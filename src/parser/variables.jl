using SeaPearl
using XML

function parse_array_variable(array_variable::Node, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

    info = attributes(array_variable)
    dimensions = parse_dimensions(info["size"])
    id = info["id"]
    
    raw_domain = children(array_variable)[1].value

    seapearl_array_var = fill(SeaPearl.IntVar(0, 0, "default", trailer), tuple(dimensions...))
    #Different domain for variables
    if isnothing(raw_domain)
        for variable in children(array_variable)
            raw_domain = children(variable)[1].value
            domain = parse_variable_domain(raw_domain)
            min_value, max_value, missing_values = sort_intervals(domain)
            #Set of variable with same domain
            ids = split(attributes(variable)["for"], " ")
            for id in ids
                var = SeaPearl.IntVar(min_value, max_value, string(id), trailer)
                for v in missing_values
                    var.domain.remove(v)
                end
                idx = map((x) -> x + 1, tuple(parse_dimensions(id)...))
                SeaPearl.addVariable!(model, var)
                seapearl_array_var[idx...] = var
            end
        end
    
    #Same domain for all variables
    else
        domain = parse_variable_domain(raw_domain)
        min_value, max_value, missing_values = sort_intervals(domain)
        
        for idx in CartesianIndices(seapearl_array_var)
            str_idx = "[" * join([string(idx[i]-1) for i in 1:length(idx)], "][") * "]"
            var = SeaPearl.IntVar(min_value, max_value, id * str_idx, trailer)
            for v in missing_values
                var.domain.remove(v)
            end
            seapearl_array_var[idx] = var
        end
    end
    
    return seapearl_array_var
end

function parse_variable_domain(raw_domain::String)
    """
    Get the domain

    Args:
        raw_domain: domaine exprimé en chaîne de caractères

    Returns:
        domain: Tableau de tableaux d'entiers ou de flottants
    """
    domain = Vector{Int}[]
    sub_domains = split(replace(replace(raw_domain, ".."=>","), "infinity"=>"inf"), " ")
    sub_domains = [dom_element for dom_element in sub_domains]
    for sub_domain in sub_domains
        if sub_domain == ""
            continue
        end
        end_index = findnext(",", sub_domain, 1)[1]
        if !isnothing(end_index)
            first, last = sub_domain[1:end_index-1], sub_domain[end_index+1:end]
            if first == "inf"
                lower_bound = typemin(Int)
            else
                lower_bound = parse(Int64, first)
            end

            if last == "inf"
                upper_bound = typemax(Int)
            else
                upper_bound = parse(Int64, last)
            end
            push!(domain, [lower_bound, upper_bound])

        else
            push!(domain, [parse(Int64, sub_domain)])
        end
    end
    return domain
end



function parse_dimensions(dim::AbstractString)
    """
    Get indexes from a string 'x[3][9][2]' or just '[3][9][2]' in an array (here : [3,9,2])

    Args:
        dim: string of type 'x[3][9][2]' or just '[3][9][2]'

    Returns:
        dim: Array [3,9,2]
    """

    # Remplacer les caractères du type [] par [:]
    dim = replace(dim, "[]" => "[:]")

    # Supprimer les caractères "[" et "]"
    dim = replace(dim, "[" => ",", "]" => "")
    # Diviser la chaîne en sous-chaînes
    dim = split(dim, ",")[2:end]

    # Convertir les sous-chaînes en entiers
    dim = parse.(Int, dim)

    return dim
end


function sort_intervals(intervals::Vector{Vector{Int64}})
    
    #Si seulement un interval ou singleton
    if length(intervals) == 1
        domain = intervals[1]
        if length(domain) == 1
            return domain[1], domain[1], []
        else
            return domain[1], domain[2], []
        end
    end

    # Séparer les intervalles et les singletons
    singletons = Int[]
    ranges = Int[]
    for x in intervals
        if length(x) == 1
            push!(singletons, x[1])
        elseif length(x) == 2
            for v = x[1]:x[2]+1
                push!(ranges, v)
            end
        else
            throw(ArgumentError("Invalid input: $(string(x))"))
        end
    end
    
    # Concaténer les singletons et les intervalles triés
    result = sort([singletons..., ranges...])
    
    min_val = result[1]
    max_val = result[end]
    
    
    # Calculer les entiers entre le minimum et le maximum qui ne sont pas dans l'ensemble
    missing_values = Int[]
    if !isempty(result)
        for i in min_val:max_val
            if !(i in result)
                push!(missing_values, i)
            end
        end
    end
    
    # Retourner les résultats sous forme de tuple
    return min_val, max_val, missing_values
end
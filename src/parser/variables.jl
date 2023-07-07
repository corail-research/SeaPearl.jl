using XML

"""
    parse_all_variables(variables::Node, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Take the XML node of the variables and parse all the variables into a dictionnary : dict_variables[id_variable] = value_variable
"""
function parse_all_variables(variables::Node, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    dict_variables = Dict{String, Any}()
    dict_missing_values = Dict{String, Vector{Int}}()

    for var in XML.children(variables)
        id = XML.attributes(var)["id"]
        if var.tag == "array"
            dict_variables[id] = SeaPearl.parse_array_variable(var, model, trailer)
        end
    
        if var.tag == "var"
            dict_variables[id] = SeaPearl.parse_integer_variable(var, model, trailer, dict_missing_values)
        end
    end
    return dict_variables
end

"""
    parse_integer_variable(integer_variable::Node, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer, dict_missing_values::Dict{String, Vector{Int}}) 

Parse an integer variable and add it to the model.
"""
function parse_integer_variable(integer_variable::Node, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer, dict_missing_values::Dict{String, Vector{Int}})
    info = XML.attributes(integer_variable)
    id = info["id"]

    if haskey(info, "as")
        as_id = info["as"]
        as_domain = model.variables[as_id].domain
        min_value, max_value = minimum(as_domain), maximum(as_domain)
        
        missing_values = dict_missing_values[as_id]
    else
        raw_domain = get_node_string(integer_variable)
        domain = parse_variable_domain(raw_domain)
        min_value, max_value, missing_values = sort_intervals(domain)

        dict_missing_values[id] = missing_values
    end
    
    var = SeaPearl.IntVar(min_value, max_value, string(id), trailer)
    for v in missing_values
        SeaPearl.remove!(var.domain, v)
    end
    SeaPearl.addVariable!(model, var)

    return var
end

"""
    parse_array_variable(array_variable::Node, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse an array variable and add it to the model.
"""
function parse_array_variable(array_variable::Node, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

    info = XML.attributes(array_variable)
    dimensions = parse_dimensions(info["size"])
    id = info["id"]


    raw_domain = get_node_string(array_variable)

    seapearl_array_var = fill(SeaPearl.IntVar(0, 0, "default", trailer), tuple(dimensions...))

    #Different domain for variables
    if isnothing(raw_domain)
        for variable in XML.children(array_variable)

            #Domain definition
            raw_domain = get_node_string(variable)
            domain = parse_variable_domain(raw_domain)
            min_value, max_value, missing_values = sort_intervals(domain)

            #Sets of variables with same domain
            var_sets = split(XML.attributes(variable)["for"], " ")
            for var_set in var_sets
                str_indexes = "[" * split(var_set, "[", limit=2)[2]
                indexes = get_indexes(str_indexes, dimensions)

                for idx in indexes
                    id_var = id * "[" * join(idx, "][") * "]"
                    var = SeaPearl.IntVar(min_value, max_value, string(id_var), trailer)

                    #Remove missing values from variables domain
                    for v in missing_values
                        SeaPearl.remove!(var.domain, v)
                    end

                    #Put variable into the variable matrix and the model
                    idx = map((x) -> x + 1, tuple(idx...))
                    SeaPearl.addVariable!(model, var)
                    seapearl_array_var[idx...] = var
                end
            end
        end

        # For variables not declared 
        for idx in CartesianIndices(seapearl_array_var)
            if seapearl_array_var[idx].id == "default"
                str_idx = "[" * join([string(idx[i] - 1) for i in 1:length(idx)], "][") * "]"
                var = SeaPearl.IntVar(0, 0, id * str_idx, trailer)
                SeaPearl.addVariable!(model, var)
                seapearl_array_var[idx] = var
            end            
        end
        
    #Same domain for all variables
    else
        domain = parse_variable_domain(raw_domain)
        min_value, max_value, missing_values = sort_intervals(domain)

        for idx in CartesianIndices(seapearl_array_var)
            str_idx = "[" * join([string(idx[i] - 1) for i in 1:length(idx)], "][") * "]"
            var = SeaPearl.IntVar(min_value, max_value, id * str_idx, trailer)
            for v in missing_values
                SeaPearl.remove!(var.domain, v)
            end
            SeaPearl.addVariable!(model, var)
            seapearl_array_var[idx] = var
        end
    end

    return seapearl_array_var
end

function parse_variable_domain(raw_domain::String)
    """
    Get the domain

    Args:
        raw_domain: domain expressed as a character string

    Returns:
        domain: Array of integer or float arrays
    """
    domain = Vector{Int}[]
    sub_domains = split(raw_domain, " ")
    for sub_domain in sub_domains
        if sub_domain == ""
            continue
        end

        bounds = split(sub_domain, "..")

        if length(bounds) > 1
            first, last = bounds[1], bounds[2]
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

function get_indexes(str_indexes::AbstractString, dimensions::Vector{Int})
    
    str_indexes = split(str_indexes[2:end-1], "][")

    indexes = Vector{Vector{Int}}()
    push!(indexes, Int[])
  
    for (i,str_idx) in enumerate(str_indexes)
        
        if str_idx == ""
            new_indexes = Vector{Vector{Int}}()
            for idx = 0:dimensions[i]-1
                for idx_vector in indexes
                    idx_vector_copy = copy(idx_vector)
                    push!(idx_vector_copy, idx)
                    push!(new_indexes, idx_vector_copy)
                end
            end
            indexes = new_indexes

        else
            bounds = split(str_idx, "..")
            if length(bounds) == 1
                idx = parse(Int, bounds[1])
                for idx_vector in indexes
                    push!(idx_vector, idx)
                    
                end

            else
                new_indexes = Vector{Vector{Int}}()

                lower_idx = parse(Int, bounds[1])
                upper_idx = parse(Int, bounds[2])

                for idx = lower_idx:upper_idx
                    for idx_vector in indexes
                        idx_vector_copy = copy(idx_vector)
                        push!(idx_vector_copy, idx)
                        push!(new_indexes, idx_vector_copy)
                    end
                end
                indexes = new_indexes
            end
        end
    end
    return indexes
end


function parse_dimensions(dim::AbstractString)
    """
    Get indexes from a string 'x[3][9][2]' or just '[3][9][2]' in an array (here : [3,9,2])

    Args:
        dim: string of type 'x[3][9][2]' or just '[3][9][2]'

    Returns:
        dim: Array [3,9,2]
    """

    # Delete the characters "[" and "]"
    dim = replace(dim, "[" => ",", "]" => "")
    # Dividing the string into sub-string
    dim = split(dim, ",")[2:end]

    # Convert substrings to integers
    dim = parse.(Int, dim)

    return dim
end

"""
    sort_intervals(intervals::Vector{Vector{Int64}})

Sort intervals and singletons and return the minimum and maximum value of the set and the missing values
"""
function sort_intervals(intervals::Vector{Vector{Int64}})

    # If only is an interval or a singleton
    if length(intervals) == 1
        domain = intervals[1]
        if length(domain) == 1
            return domain[1], domain[1], []
        else
            return domain[1], domain[2], []
        end
    end

    # Separating intervals and singletons
    singletons = Int[]
    ranges = Int[]
    for x in intervals
        if length(x) == 1
            push!(singletons, x[1])
        elseif length(x) == 2
            for v = x[1]:x[2]
                push!(ranges, v)
            end
        else
            throw(ArgumentError("Invalid input: $(string(x))"))
        end
    end

    # Concatenate singletons and sorted intervals
    result = sort([singletons..., ranges...])

    min_val = result[1]
    max_val = result[end]

    # Calculate the integers between the minimum and maximum that are not in the set
    missing_values = Int[]
    if !isempty(result)
        for i in min_val:max_val
            if !(i in result)
                push!(missing_values, i)
            end
        end
    end

    # Return results as a tuple
    return min_val, max_val, missing_values
end

"""
    get_constraint_variables(str_constraint_variables::AbstractString, variables::Dict{String, Any})

Return the variables appearing in the constaint string.
"""
function get_constraint_variables(str_constraint_variables::AbstractString, variables::Dict{String, Any})
    constraint_variables = SeaPearl.AbstractIntVar[]

    for str_variable in split(str_constraint_variables, " ")
        # Delete "]"
        str = replace(str_variable, "]" => "")
            
        # Divide string into array of substring
        str_vector = split(str, "[")

        id, str_idx = str_vector[1], str_vector[2:end]

        #Get variable(s) with id
        var = variables[id]

        # Simple variable 
        if length(str_vector) == 1
            push!(constraint_variables, var)
            
        # Array variables
        else
            int_idx = []
            for i in str_idx
                #All index have to be considered
                if i == ""
                    push!(int_idx, [:][1])
                else
                    bounds = split(i, "..")
                    lower_bound = parse(Int, bounds[1]) + 1

                    #A subset from the array is considered
                    if length(bounds) == 2
                        upper_bound = parse(Int, bounds[2]) + 1
                        push!(int_idx, [lower_bound:upper_bound][1])
                    
                    #Only one index is considered
                    else
                        push!(int_idx, lower_bound)
                    end
                end
            end
            vars = var[int_idx...]
            if isa(vars, Array)
                push!(constraint_variables, vars...)
            else
                push!(constraint_variables, vars)
            end
        end

    end
    return constraint_variables
end
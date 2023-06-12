"""
    parse_group(group::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse the group constraint from a string and apply it to the constraint programming model.
"""
function parse_group(group::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    constraint_node, args_nodes = XML.children(group)[1], XML.children(group)[2:end]

    tag = constraint_node.tag

    if tag == "allDifferent"
        allDifferent_pattern = get_node_string(constraint_node)
        for constraint_variables in args_nodes
            str_constraint_variables = fill_pattern!(allDifferent_pattern, constraint_variables, variables)
            parse_allDifferent_expression!(str_constraint_variables, variables, model, trailer)
        end
    end 

    if tag == "intension"
        intension_pattern = get_node_string(constraint_node)
        for constraint_variables in args_nodes
            str_constraint = fill_pattern!(intension_pattern, constraint_variables, variables)
            parse_intension_expression(str_constraint, variables, model, trailer)
        end
    end

    if tag == "extension"

        list_pattern = get_node_string(find_element(constraint_node, "list"))

        support_node = find_element(constraint_node, "supports")
        if isnothing(support_node)
            str_conflict = get_node_string(find_element(constraint_node, "conflicts"))
            for constraint_variables in args_nodes
                str_list = fill_pattern!(list_pattern, constraint_variables, variables)
                parse_conflict_extension_expression!(str_list, str_conflict, variables, model, trailer)
            end
        else 
            str_support = get_node_string(support_node)
            for constraint_variables in args_nodes
                str_list = fill_pattern!(list_pattern, constraint_variables, variables)
                parse_support_extension_expression(str_list, str_support, variables, model, trailer)
            end
        end
        
    end

    if tag == "sum"
        condition_pattern = get_node_string(find_element(constraint_node, "condition"))
        list_pattern = get_node_string(find_element(constraint_node, "list"))
        if isnothing(find_element(constraint_node, "coeffs"))
            str_coeffs = ""
        else 
            str_coeffs = get_node_string(find_element(constraint_node, "coeffs"))
        end

        for constraint_variables in args_nodes
            str_condition, str_list = fill_sum_patterns!(condition_pattern, list_pattern, constraint_variables, variables)

            parse_sum_constraint_expression(str_condition, str_list, str_coeffs, variables, model, trailer)
        end
    end

end

"""
    fill_pattern!(pattern::AbstractString, constraint_variables::Node, variables::Dict{String, Any})

Fill the pattern with the variables of the constraint_variables node.
"""
function fill_pattern!(pattern::AbstractString, constraint_variables::Node, variables::Dict{String, Any})
    if !occursin("%", pattern)
        return pattern
    end
    
    str_vars = get_node_string(constraint_variables)

    if pattern == "%..."
        return str_vars
    end

    str_vars_split = split(str_vars, " ")
    nb_percentage = count(i->(i=='%'), pattern)

    if nb_percentage != length(str_vars_split)    
        new_str_vars_split = get_complete_str_variable_vector(str_vars_split, variables)
    else
        new_str_vars_split = str_vars_split
    end

    return replace_percent!(pattern, new_str_vars_split)
end

"""
    get_all_str_variables(str_variables::AbstractString, dimensions::Vector{Int})

Get all the string variables from a string variable.
"""
function get_all_str_variables(str_variables::AbstractString, dimensions::Vector{Int})
    
    id_var, str_indexes = split(str_variables[1:end-1], "[", limit=2)
    str_indexes = split(str_indexes, "][")

    str_variables = Vector{AbstractString}()
    push!(str_variables, id_var)
    
    for (i,str_idx) in enumerate(str_indexes)
        
        if str_idx == ""
            new_str_variables = Vector{AbstractString}()
            for str_var in str_variables
                for idx = 0:dimensions[i]-1
                    str_var_copy = str_var
                    str_var_copy *= "[$idx]"
                    push!(new_str_variables, str_var_copy)
                end
            end
            str_variables = new_str_variables

        else
            bounds = split(str_idx, "..")
            if length(bounds) == 1
                idx = parse(Int, bounds[1])
                for (j,str_var) in enumerate(str_variables)
                    str_variables[j] = str_var * "[$idx]"
                end
            else
                new_str_variables = Vector{AbstractString}()

                lower_idx = parse(Int, bounds[1])
                upper_idx = parse(Int, bounds[2])

                for str_var in str_variables
                    for idx = lower_idx:upper_idx
                        str_var_copy = str_var
                        str_var_copy *= "[$idx]"
                        push!(new_str_variables, str_var_copy)
                    end
                end
                str_variables = new_str_variables
            end
        end
    end
    return str_variables
end

"""
    fill_sum_patterns!(condition_pattern::AbstractString, list_pattern::AbstractString, constraint_variables::Node, variables::Dict{String, Any})

Fill the condition and list pattern with the variables of the constraint_variables node.
"""
function fill_sum_patterns!(condition_pattern::AbstractString, list_pattern::AbstractString, constraint_variables::Node, variables::Dict{String, Any})
    str_vars = get_node_string(constraint_variables)

    str_vars_split = split(str_vars, " ")

    new_str_var_split = get_complete_str_variable_vector(str_vars_split, variables)

    index_bool = [true for var in new_str_var_split]

    new_condition_pattern = replace_percent_v2!(condition_pattern, new_str_var_split, index_bool, false)
    new_list_pattern = replace_percent_v2!(list_pattern, new_str_var_split, index_bool, false)

    if isnothing(new_condition_pattern)
        new_condition_pattern = replace_percent_v2!(condition_pattern, new_str_var_split, index_bool, true)
    end
    if isnothing(new_list_pattern)
        new_list_pattern = replace_percent_v2!(list_pattern, new_str_var_split, index_bool, true)
    end

    return new_condition_pattern, new_list_pattern
end


function get_complete_str_variable_vector(str_variable_vector::Vector{<:AbstractString}, variables::Dict{String, Any})
    new_str_variable_vector = Vector{AbstractString}()
    for str_var in str_variable_vector
        var_split = split(str_var, "[", limit=2)
        if length(var_split) == 1
            push!(new_str_variable_vector, str_var)
        else 
            id_var = var_split[1]
            dimensions = collect(size(variables[id_var]))
            push!(new_str_variable_vector, get_all_str_variables(str_var, dimensions)...)
        end
    end

    return new_str_variable_vector
end


function replace_percent!(str_pattern::AbstractString, str_variable_vector::Vector{<:AbstractString})
    filled_pattern = str_pattern
    for (i, var) in enumerate(reverse(str_variable_vector))
        reverse_i = length(str_variable_vector) - i + 1
        filled_pattern = replace(filled_pattern, "%" * string(reverse_i-1) => string(var))
    end
    return string(split(filled_pattern, " %")[1])
end

function replace_percent_v2!(str_pattern::AbstractString, str_variable_vector::Vector{<:AbstractString}, index_bool::Vector{<:Bool}, last_pattern::Bool=true)
    if !occursin("%", str_pattern)
        return str_pattern
    end
    if str_pattern == "%..."
        if last_pattern
            return join([x for (x, y) in zip(str_variable_vector, index_bool) if y], " ")
        else
            return nothing 
        end
    end

    filled_pattern = str_pattern
    for (i, var) in enumerate(reverse(str_variable_vector))
        reverse_i = length(str_variable_vector) - i + 1
        if occursin("%" * string(reverse_i-1), filled_pattern)
            index_bool[reverse_i] = false
        end
        filled_pattern = replace(filled_pattern, "%" * string(reverse_i-1) => string(var))
    end
    return string(split(filled_pattern, " %")[1])

end
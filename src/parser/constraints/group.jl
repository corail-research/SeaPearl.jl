function parse_group(group::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    constraint_node, args_nodes = XML.children(group)[1], XML.children(group)[2:end]

    tag = constraint_node.tag

    if tag == "allDifferent"
        allDifferent_pattern = get_node_string(constraint_node)
        for constraint_variables in args_nodes
            str_constraint_variables = fill_pattern(allDifferent_pattern, constraint_variables)
            parse_allDifferent_expression!(str_constraint_variables, variables, model, trailer)
        end
    end 

    if tag == "intension"
        intension_pattern = get_node_string(constraint_node)
        for constraint_variables in args_nodes
            str_constraint = fill_pattern(intension_pattern, constraint_variables)
            parse_intension_expression(str_constraint, variables, model, trailer)
        end
    end

    if tag == "extension"

        list_pattern = get_node_string(find_element(constraint_node, "list"))

        support_node = find_element(constraint_node, "supports")
        if isnothing(support_node)
            str_conflict = get_node_string(find_element(constraint_node, "conflicts"))
            for constraint_variables in args_nodes
                str_list = fill_pattern(list_pattern, constraint_variables)
                parse_conflict_extension_expression!(str_list, str_conflict, variables, model, trailer)
            end
        else 
            str_support = get_node_string(support_node)
            for constraint_variables in args_nodes
                str_list = fill_pattern(list_pattern, constraint_variables)
                parse_support_extension_expression(str_list, str_support, variables, model, trailer)
            end
        end
        
    end

    if tag == "sum"
        str_relation = get_node_string(find_element(constraint_node, "condition"))
        list_pattern = get_node_string(find_element(constraint_node, "list"))
        if isnothing(find_element(constraint_node, "coeffs"))
            str_coeffs = ""
        else 
            str_coeffs = get_node_string(find_element(constraint_node, "coeffs"))
        end

        for constraint_variables in args_nodes
            str_list = fill_pattern(list_pattern, constraint_variables)
            parse_sum_constraint_expression(str_relation, str_list, str_coeffs, variables, model, trailer)
        end
    end

end


function fill_pattern(pattern::AbstractString, constraint_variables::Node)
    str_vars = get_node_string(constraint_variables)

    if pattern == "%..."
        return str_vars
    end

    str_vars_split = split(str_vars, " ")
    filled_pattern = pattern

    for (i, var) in enumerate(str_vars_split)
        filled_pattern = replace(filled_pattern, "%" * string(i-1) => string(var))
    end

    return string(split(filled_pattern, " %")[1])
end
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
    nb_percentage = count(i->(i=='%'), filled_pattern)

    new_str_vars_split = fill("0", size(str_vars_split))

    j = 0
    if nb_percentage != length(str_vars_split)     
        for (i,var) in enumerate(str_vars_split)
            if occursin("..", var)
                str_list = get_var_dot_expression(var)
                for s in str_list
                    if j != 0
                        insert!(new_str_vars_split, i+j, s)
                    else
                        new_str_vars_split[i+j] = s
                    end
                    j += 1
                end
                j -= 1
            else
                new_str_vars_split[i+j] = var
            end
        end
    else
        new_str_vars_split = str_vars_split
    end
    for (i, var) in enumerate(new_str_vars_split)
        filled_pattern = replace(filled_pattern, "%" * string(i-1) => string(var))
    end
    return string(split(filled_pattern, " %")[1])
end

function get_var_dot_expression(string_with_dot::AbstractString)
    str_list = String[]
    str = replace(string_with_dot, ".." => "%")

    idx_perc = findfirst(x -> x == '%', str)

    idx_bracket_inf_list = findall(x -> x == '[', str[1:idx_perc])
    idx_bracket_inf = idx_bracket_inf_list[end]

    idx_bracket_sup_list = findall(x -> x == ']', str[idx_perc:end])
    idx_bracket_sup = idx_bracket_sup_list[1] + idx_perc - 1

    nb_inf = 0
    nb_sup = 0

    nb_inf_str = str[idx_bracket_inf+1:idx_perc-1]
    nb_sup_str = str[idx_perc+1:idx_bracket_sup-1]
    
    new_string = str[1:idx_bracket_inf] * "" * str[idx_perc:idx_perc] * "" * str[idx_bracket_sup:end]


    if is_digit(nb_inf_str)
        nb_inf = parse(Int, nb_inf_str)
    else
        println("Error: the number between [ and % is not an integer")
    end
    
    if is_digit(nb_sup_str)
        nb_sup = parse(Int, nb_sup_str)
    else
        println("Error: the number between % and ] is not an integer")
    end
    for i in nb_inf:nb_sup
        push!(str_list, replace(new_string, "%" => string(i)))
    end
    return str_list
end
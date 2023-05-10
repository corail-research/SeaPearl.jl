function parse_extension_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

    str_list = get_node_string(find_element(constraint, "list"))


    support_node = find_element(constraint, "supports")

    if isnothing(support_node)
        conflict_node = find_element(constraint, "conflicts")  

        str_conflict = get_node_string(conflict_node)
    
        parse_conflict_extension_expression(str_list, str_conflict, variables, model, trailer)

    else
        str_support = get_node_string(support_node)
        parse_support_extension_expression(str_list, str_support, variables, model, trailer)
    end

end

function parse_support_extension_expression(str_list::AbstractString, str_support::AbstractString, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    constraint_variables = get_constraint_variables(str_list, variables)

    str_tuples = split(str_support[2:end-1], ")(")
    
    table = hcat([map(x -> parse_table_integer(x), split(tuple, ",")) for tuple in str_tuples]...)
    if eltype(table) == Int
        constraint = SeaPearl.TableConstraint(constraint_variables, table, trailer)
    else
        constraint = SeaPearl.ShortTableConstraint(constraint_variables, table, trailer)
    end
    SeaPearl.addConstraint!(model, constraint)
end

function parse_conflict_extension_expression(str_list::String, str_conflict::String, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    constraint_variables = get_constraint_variables(str_list, variables)

    str_tuples = split(str_conflict[2:end-1], ")(")
    table = hcat([map(x -> parse(Int, x), split(tuple, ",")) for tuple in str_tuples]...)

    constraint = SeaPearl.NegativeTableConstraint(constraint_variables, table, trailer)
    SeaPearl.addConstraint!(model, constraint)
end


function parse_table_integer(str_int::AbstractString)
    if is_digit(str_int)
        return parse(Int, str_int)
    else
        return str_int
    end
end
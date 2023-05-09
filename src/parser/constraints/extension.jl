function parse_extension_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

    str_list = get_node_string(find_element(constraint, "list"))


    support_node = find_element(constraint, "supports")

    #TODO : contrainte extension conflict (negative table à faire)
    if isnothing(support_node)
        conflict_node = find_element(constraint, "conflicts")  

        str_conflict = get_node_string(conflict_node)
    
        parse_conflict_extension_expression(str_list, str_conflict, variables, model, trailer)

    else
        str_support = XML.children(support_node)[1].value
        parse_support_extension_expression(str_list, str_support, variables, model, trailer)
    end

end

function parse_support_extension_expression(str_list::String, str_support::String, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    constraint_variables = get_constraint_variables(str_list, variables)

    str_tuples = split(str_support[2:end-1], ")(")
    table = hcat([map(x -> parse(Int, x), split(tuple, ",")) for tuple in str_tuples]...)

    constraint = SeaPearl.TableConstraint(constraint_variables, table, trailer)
    SeaPearl.addConstraint!(model, constraint)
end

function parse_conflict_extension_expression(str_list::String, str_conflict::String, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    println("TODO: IMPLEMENT NEGATIVE TABLE CONSTRAINT")
end

using XML


function parse_allDifferent_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    str_constraint_variables = get_node_string(constraint)
    parse_allDifferent_expression(str_constraint_variables, variables, model, trailer)
end


function parse_allDifferent_expression(str_constraint_variables::AbstractString, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    allDiff_vars = get_constraint_variables(str_constraint_variables, variables)
    con = SeaPearl.AllDifferent(allDiff_vars, trailer)
    SeaPearl.addConstraint!(model, con)
end

using XML

"""
    parse_allDifferent_constraint!(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse the allDifferent constraint from an XML node and apply it to the constraint programming model.

# Arguments
- `constraint::Node`: XML node that contains the allDifferent constraint.
- `variables::Dict{String, Any}`: A dictionary mapping variable names to their respective SeaPearl variable objects.
- `model::SeaPearl.CPModel`: Constraint programming model where the constraint will be added.
- `trailer::SeaPearl.Trailer`: An object that keeps track of changes during search to allow for efficient backtracking.
"""
function parse_allDifferent_constraint!(constraint::Node, variables::Dict{String,Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    str_constraint_variables = get_node_string(constraint)
    parse_allDifferent_expression!(str_constraint_variables, variables, model, trailer)
end

"""
    parse_allDifferent_expression!(str_constraint_variables::AbstractString, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse the allDifferent constraint from a string and apply it to the constraint programming model.

# Arguments
- `str_constraint_variables::AbstractString`: A string that contains the allDifferent constraint.
- `variables::Dict{String, Any}`: A dictionary mapping variable names to their respective SeaPearl variable objects.
- `model::SeaPearl.CPModel`: Constraint programming model where the constraint will be added.
- `trailer::SeaPearl.Trailer`: An object that keeps track of changes during search to allow for efficient backtracking.
"""
function parse_allDifferent_expression!(str_constraint_variables::AbstractString, variables::Dict{String,Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    allDiff_vars = get_constraint_variables(str_constraint_variables, variables)
    con = SeaPearl.AllDifferent(allDiff_vars, trailer)
    SeaPearl.addConstraint!(model, con)
end

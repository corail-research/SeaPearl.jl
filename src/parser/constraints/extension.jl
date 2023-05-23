"""
    parse_extension_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse an extension constraint from an XML node and apply it to the constraint programming model.

# Arguments
- `constraint::Node`: XML node that contains the extension constraint.
- `variables::Dict{String, Any}`: A dictionary mapping variable names to their respective SeaPearl variable objects.
- `model::SeaPearl.CPModel`: Constraint programming model where the constraint will be added.
- `trailer::SeaPearl.Trailer`: An object that keeps track of changes during search to allow for efficient backtracking.
"""
function parse_extension_constraint(constraint::Node, variables::Dict{String,Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    str_list = get_node_string(find_element(constraint, "list"))
    support_node = find_element(constraint, "supports")

    if isnothing(support_node)
        conflict_node = find_element(constraint, "conflicts")

        
        if isnothing(conflict_node)
            error("Extension constraint has to contain 'supports' or 'conflicts' node")
        
        elseif !isnothing(conflict_node.children)
            str_conflict = get_node_string(conflict_node)

            parse_conflict_extension_expression!(str_list, str_conflict, variables, model, trailer)
        end

    else
        str_support = get_node_string(support_node)
        parse_support_extension_expression(str_list, str_support, variables, model, trailer)
    end

end

"""
    parse_support_extension_expression(str_list::AbstractString, str_support::AbstractString, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse a support extension expression from a string and apply it to the constraint programming model.

# Arguments
- `str_list::AbstractString`: A string that contains the list of variables.
- `str_support::AbstractString`: A string that contains the support tuples.
- `variables::Dict{String, Any}`: A dictionary mapping variable names to their respective SeaPearl variable objects.
- `model::SeaPearl.CPModel`: Constraint programming model where the constraint will be added.
- `trailer::SeaPearl.Trailer`: An object that keeps track of changes during search to allow for efficient backtracking.
"""
function parse_support_extension_expression(str_list::AbstractString, str_support::AbstractString, variables::Dict{String,Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
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

"""
    parse_conflict_extension_expression!(str_list::String, str_conflict::String, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse a conflict extension expression from a string and apply it to the constraint programming model.

# Arguments
- `str_list::AbstractString`: A string that contains the list of variables.
- `str_conflict::AbstractString`: A string that contains the conflict tuples.
- `variables::Dict{String, Any}`: A dictionary mapping variable names to their respective SeaPearl variable objects.
- `model::SeaPearl.CPModel`: Constraint programming model where the constraint will be added.
- `trailer::SeaPearl.Trailer`: An object that keeps track of changes during search to allow for efficient backtracking.
"""
function parse_conflict_extension_expression!(str_list::AbstractString, str_conflict::AbstractString, variables::Dict{String,Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    constraint_variables = get_constraint_variables(str_list, variables)

    str_tuples = split(str_conflict[2:end-1], ")(")
    table = hcat([map(x -> parse(Int, x), split(tuple, ",")) for tuple in str_tuples]...)

    constraint = SeaPearl.NegativeTableConstraint(constraint_variables, table, trailer)
    SeaPearl.addConstraint!(model, constraint)
end

"""
    parse_table_integer(str_int::AbstractString)

Parses a table integer from a string.

# Arguments
- `str_int::AbstractString`: A string that contains the integer to be parsed.

# Returns
- An integer if the string represents an integer, otherwise returns the original string.
"""
function parse_table_integer(str_int::AbstractString)
    if is_digit(str_int)
        return parse(Int, str_int)
    else
        return str_int
    end
end
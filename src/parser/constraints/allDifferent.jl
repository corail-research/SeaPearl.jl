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

"""
    get_constraint_variables(str_constraint_variables, variables)

Parse the variables from a string that defines a constraint.

# Arguments
- `str_constraint_variables`: A string that contains the variables for a constraint.
- `variables`: A dictionary mapping variable names to their respective SeaPearl variable objects.

# Returns
- `constraint_variables`: An array of SeaPearl variables that the constraint applies to.

This function parses the variables defined in the string `str_constraint_variables`, retrieves the corresponding SeaPearl variable objects from the dictionary `variables`, and returns an array of these variable objects. The parsing of the string considers different formats, including ranges and individual indices. If a variable is an array, all its elements are added to the array of constraint variables.
"""

function get_constraint_variables(str_constraint_variables, variables)
    constraint_variables = SeaPearl.IntVar[]

    for str_variable in split(str_constraint_variables, " ")
        # Delete "]"
        str = replace(str_variable, "]" => "")

        # Divide string into array of substring
        str_vector = split(str, "[")

        id, str_idx = str_vector[1], str_vector[2:end]

        #Get array with id
        var = variables[id]

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
    return constraint_variables
end


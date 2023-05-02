using XML

function parse_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    tag = constraint.tag

    if tag == "allDifferent"
        str_constraint_variables = children(constraint)[1].value
        allDiff_vars = get_constraint_variables(str_constraint_variables, variables)
        con = SeaPearl.AllDifferent(allDiff_vars, trailer)
        SeaPearl.addConstraint!(model, con)
    end

end


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
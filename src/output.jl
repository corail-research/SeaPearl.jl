using CSV, DataFrames

"""
    solve_XCSP3_instancesolve_XCSP3_instance(file_path::AbstractString, time_limit::Union{Nothing, Int}=nothing, memory_limit::Union{Nothing, Int}=nothing)

# Arguments
- `file_path::AbstractString`: relative path to XCSP3 instance file (.xml), can be CSP or COP
- `time_limit::Union{Nothing, Int}`: Searching time limit for solving the instance
- `memory_limit::Union{Nothing, Int}`: the reversible representation of the table.

"""
function solve_XCSP3_instance(file_path::AbstractString, strategy::SearchStrategy=DFSearch(), time_limit::Union{Nothing, Int}=nothing, memory_limit::Union{Nothing, Int}=nothing, save_performance::Bool=false, save_path::AbstractString="")

    solving_time = @elapsed begin 
        parsing_time = @elapsed begin
            model, trailer, dict_variables = SeaPearl.parse_xml_file(file_path)
        end
        nb_var = get_initial_variable_number(dict_variables)
        nb_con = get_initial_constraint_number(file_path)

        #Time limit 
        if !isnothing(time_limit)
            model.limit.searchingTime = time_limit
        end

        #Memory limit 
        if !isnothing(memory_limit)
            model.limit.searchingMemory = memory_limit
        end

        # For CSP problem, only one solution required
        if isnothing(model.objective)
            type = "CSP"
            model.limit.numberOfSolutions = 1
        else 
            type = "COP"
        end

        println("c Time Limit set via TIMEOUT to $(model.limit.searchingTime) s")
        println("c Initial problem consists of $nb_var variables and $nb_con constraints.")
        println("c    preprocess terminated. Elapsed time: $parsing_time s")

        SeaPearl.display_XCPS3(model)

        status = SeaPearl.solve!(model, strategy)
    end
    
    idx_sol = get_index_solution(model)

    if !isnothing(idx_sol)
        print_solutions(model, dict_variables, idx_sol)
    else 
        println("c No solution because $status")
    end
    
    println("c Total time: $solving_time s")

    if save_performance
        file_name = basename(file_path)

        column_names = ["file_name", "type", "strategy", "nb_variables", "nb_constraints", "time_limit", "memory_limit", "status", "result", "optimum_value", "solving_time", "parsing_time"]
        # Check if the file exists
        if !isfile(save_path)
            CSV.write(save_path, DataFrame([]); header=column_names)
        end

        if !isnothing(model.objective)
            optimum_value = model.statistics.objectives[idx_sol]
            if model.maximizeObjective
                optimum_value = -optimum_value
            end
        else
            optimum_value = nothing
        end

        if status == :Optimal
            if !isnothing(model.objective)
                result = "OPTIMUM FOUND"
            else
                result = "SATISTFIABLE"
            end

        elseif status == :NonOptimal
            result = "SATISTFIABLE"

        elseif status  == :Infeasible
            result = "UNSATISTFIABLE"

        else 
            if !isnothing(get_index_solution(model))
                result = "SATISTFIABLE"
            else
                result = "UNKNOWN"
            end
        end
        
        # Create the new row to add
        new_row = [file_name, type, strategy, nb_var, nb_con, time_limit, memory_limit, status, result, optimum_value, solving_time, parsing_time]
        new_row = map(x -> x === nothing ? "nothing" : x, new_row)
        
        # Convert the matrix to a DataFrame and Write the updated data to the CSV file
        CSV.write(save_path, DataFrame(hcat(new_row...), :auto); append=true)
        
    end
    return model
end


function print_solutions(model::SeaPearl.CPModel, dict_variables::Dict{String,Any}, index_solution::Int)
    
    if isnothing(model.objective)
        solution_vars = model.statistics.solutions[index_solution]
        println("v <instantiation id='sol1' type='solution'>")
    else
        solution_vars = model.statistics.solutions[index_solution]
        optimum_value = model.statistics.objectives[index_solution]
        if model.maximizeObjective
            println("v <instantiation id='sol$index_solution' type='optimum' cost='$(-optimum_value)'>")
        else
            println("v <instantiation id='sol$index_solution' type='optimum' cost='$(optimum_value)'>")
        end
    end
    
    print("v    <list> ")
    values = Int[]
    for (id, var) in dict_variables
        if isa(var, Vector) || isa(var, Matrix)
            
            print(id*"[]"^length(size(var)), " ")
            for array_var in var
                idx = array_var.id
                push!(values, solution_vars[idx])
            end
        else
            print(id, " ")
            push!(values, solution_vars[id])
        end
    end
    println("</list>")
    println("v    <values> ", join(values, " "), " </values>")
    println("v </instantiation>")
end


function get_initial_variable_number(dict_variables::Dict{String,Any})
    variable_count = 0
    for (id, var) in dict_variables
        if isa(var, Vector) || isa(var, Matrix)
            variable_count += length(var)
        else
            variable_count +=1
        end
    end
    return variable_count
end

function get_initial_constraint_number(file_path::AbstractString)
    constraint_count = 0

    # Convert document into XML node 
    doc = XML.read(file_path, XML.Node)
    instance = find_element(doc, "instance")
    constraints = find_element(instance, "constraints")

    for con in XML.children(constraints)
        constraint_count += constraint_counter(con)
    end

    return constraint_count
end

function constraint_counter(constraint_node::XML.Node)
    tag = constraint_node.tag
    constraint_count = 0

    if tag == "group"
        constraint_count = length(XML.children(constraint_node))-1

    elseif tag == "block"
        constraint_count = 0
        for con in XML.children(constraint_node)
            constraint_count += constraint_counter(con)
        end

    else 
        constraint_count = 1
    end

    return constraint_count
end

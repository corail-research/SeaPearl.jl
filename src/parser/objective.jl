function parse_objective_function(objective_node::XML.Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    info = XML.attributes(objective_node)
    
    if !isnothing(info) 
        if haskey(info, "combination")
            combination = info["combination"]
        end
    end

    objective_functions = XML.children(objective_node)

    for (idx, obj_func) in enumerate(objective_functions)
        info = XML.attributes(obj_func)

        if haskey(info, "type")
            type = info["type"]
        else 
            type = nothing
        end

        
        if haskey(info, "id")
            id = info["id"]

        else
            id = "objective_" * string(idx)
        end

        tag = obj_func.tag 

        list_node = find_element(obj_func, "list")

        if isnothing(list_node)
            str_objective_variables = get_node_string(obj_func)
            objective_variables = get_constraint_variables(str_objective_variables, variables)

        else 
            str_list = get_node_string(list_node)

            coeffs_node = find_element(obj_func, "coeffs")

            if !isnothing(coeffs_node)
                str_coeffs = get_node_string(coeffs_node)
                objective_variables = get_constraint_variables_expression(str_list, str_coeffs, variables)

            else
                objective_variables = get_constraint_variables(str_list, variables)
            end
        end

        if isnothing(type)
            objective_var = objective_variables[1]
            if tag == "minimize"
                SeaPearl.addObjective!(model, objective_var)
            else
                negative_objective_var = SeaPearl.IntVarViewOpposite(objective_var, "-" * id)
                SeaPearl.addVariable!(model, negative_objective_var)
                SeaPearl.addObjective!(model, negative_objective_var)
            end 


        elseif type == "sum"
            total_min = 0
            total_max = 0
            for var in objective_variables 
                total_min += minimum(var.domain)
                total_max += maximum(var.domain)
            end
            
            total_variable = SeaPearl.IntVar(total_min, total_max, id, trailer)
            SeaPearl.addVariable!(model, total_variable)
            SeaPearl.addConstraint!(model, SeaPearl.SumToVariable(objective_variables, total_variable, trailer))

            if tag == "minimize"
                SeaPearl.addObjective!(model, total_variable)
            else
                negative_total_variable = SeaPearl.IntVarViewOpposite(total_variable, "-" * id)
                SeaPearl.addVariable!(model, negative_total_variable)
                SeaPearl.addObjective!(model, negative_total_variable)
            end
        
        elseif type == "nValues"
            nValues = SeaPearl.init_nValues_variable(objective_variables, id, trailer)

            SeaPearl.addConstraint!(model, SeaPearl.NValuesConstraint(objective_variables, nValues, trailer))

            SeaPearl.addVariable!(model, nValues)
            SeaPearl.addObjective!(model, nValues)
        end
        

    end

    
    

    
end
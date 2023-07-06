function parse_objective_function(objective_node::XML.Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    info = XML.attributes(objective_node)
    
    if !isnothing(info) 
        if haskey(info, "combination")
            combination = info["combination"]
        end
    end

    objective_functions = XML.children(objective_node)

    for (idx, obj_func) in enumerate(objective_functions)
        
        type, id, tag = get_objective_info(obj_func, idx)
        
        objective_variables = get_objective_variables(obj_func, variables, model, trailer)

        if isnothing(type)
            objective_var = objective_variables[1]
            parse_simple_objective(objective_var, tag, model)

        elseif type == "sum"
            parse_objective_sum(objective_variables, id, tag, model, trailer)
        
        elseif type == "nValues"
            parse_objective_nValues(objective_variables, id, tag, model, trailer)
        
        elseif type == "maximum"
            parse_objective_maximum(objective_variables, id, tag, model, trailer)

        elseif type == "minimum"
            parse_objective_minimum(objective_variables, id, tag, model, trailer)
        end
    end
end


function get_objective_info(obj_function::XML.Node, index::Int)
    info = XML.attributes(obj_function)

    if !isnothing(info) && haskey(info, "type")
        type = info["type"]
    else 
        type = nothing
    end

    if !isnothing(info) && haskey(info, "id")
        id = info["id"]

    else
        id = "objective_" * string(index)
    end

    tag = obj_function.tag

    return type, id, tag
end


function get_objective_variables(obj_function::XML.Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    list_node = find_element(obj_function, "list")

    if isnothing(list_node)
        str_objective_variables = get_node_string(obj_function)
        objective_variables = get_constraint_variables(str_objective_variables, variables)

    else 
        str_list = get_node_string(list_node)

        coeffs_node = find_element(obj_function, "coeffs")

        if !isnothing(coeffs_node)
            str_coeffs = get_node_string(coeffs_node)
            objective_variables = get_constraint_variables_expression(str_list, str_coeffs, variables, model, trailer)

        else
            objective_variables = get_constraint_variables(str_list, variables)
        end
    end
    return objective_variables
end


function parse_simple_objective(objective_variable::SeaPearl.AbstractIntVar, tag::String, model::SeaPearl.CPModel)
    if tag == "minimize"
        SeaPearl.addObjective!(model, objective_variable)
    else
        SeaPearl.maximize_objective(model)
        negative_objective_var = SeaPearl.IntVarViewOpposite(objective_variable, "-" * objective_variable.id)
        SeaPearl.addVariable!(model, negative_objective_var)
        SeaPearl.addObjective!(model, negative_objective_var)
    end 
end


function parse_objective_sum(objective_variables::Vector{<:SeaPearl.AbstractIntVar}, id::String, tag::String, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    total_min = 0
    total_max = 0
    for var in objective_variables 
        total_min += minimum(var.domain)
        total_max += maximum(var.domain)
    end
    
    total_variable = SeaPearl.IntVar(total_min, total_max, id, trailer)
    SeaPearl.addVariable!(model, total_variable)
    SeaPearl.addConstraint!(model, SeaPearl.SumToVariable(objective_variables, total_variable, trailer))

    parse_simple_objective(total_variable, tag, model)
    
end


function parse_objective_nValues(objective_variables::Vector{<:SeaPearl.AbstractIntVar}, id::String, tag::String, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    nValues = SeaPearl.init_nValues_variable(objective_variables, id, trailer)
    SeaPearl.addVariable!(model, nValues)

    SeaPearl.addConstraint!(model, SeaPearl.NValuesConstraint(objective_variables, nValues, trailer))

    parse_simple_objective(nValues, tag, model)
end


function parse_objective_maximum(objective_variables::Vector{<:SeaPearl.AbstractIntVar}, id::String, tag::String, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    max_min = minimum(objective_variables[1].domain)
    max_max = maximum(objective_variables[1].domain)

    for var in objective_variables 
        min_var = minimum(var.domain)
        max_var = maximum(var.domain)
        if min_var < max_min
            max_min = min_var
        end
        if max_var > max_max
            max_max = max_var
        end
    end
    max_intVar = SeaPearl.IntVar(max_min, max_max, id, trailer)
    SeaPearl.addVariable!(model, max_intVar)
    
    SeaPearl.addConstraint!(model, SeaPearl.MaximumConstraint(objective_variables, max_intVar, trailer))
    
    parse_simple_objective(max_intVar, tag, model)
end


function parse_objective_minimum(objective_variables::Vector{<:SeaPearl.AbstractIntVar}, id::String, tag::String, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    min_min = minimum(objective_variables[1].domain)
    min_max = maximum(objective_variables[1].domain)

    for var in objective_variables 
        min_var = minimum(var.domain)
        max_var = maximum(var.domain)
        if min_var < min_min
            min_min = min_var
        end
        if max_var > min_max
            min_max = max_var
        end
    end
    min_intVar = SeaPearl.IntVar(min_min, min_max, id, trailer)
    SeaPearl.addVariable!(model, min_intVar)
    
    SeaPearl.addConstraint!(model, SeaPearl.MinimumConstraint(objective_variables, min_intVar, trailer))
    
    parse_simple_objective(min_intVar, tag, model)
end
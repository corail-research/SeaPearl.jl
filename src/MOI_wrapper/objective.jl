
"""
set and get function overloads
"""
#MOI.get(model::Optimizer, ::MOI.ObjectiveSense) = model.inner.sense

"""
function MOI.set(model::Optimizer, ::MOI.ObjectiveSense, sense::MOI.OptimizationSense)
    model.inner.sense = sense
    return
end
"""

"""
    MOI.set(model::Optimizer, MOI.ObjectiveFunction, func<:AbstractScalarFunction)

Set the objective function of your model. 
Support linear ones only at the moment put we will move to non-linear support soon. 
"""

function MOI.set(model::Optimizer, ::MOI.ObjectiveFunction, svf::MOI.SingleVariable)
    # get the VariableIndexs, convert them to strings and create 
    id = string(svf.variable.value)

    # tell the inner model that it is its objective !
    model.cpmodel.objective = model.cpmodel.variables[id]
end

function MOI.set(model::Optimizer, ::MOI.ObjectiveFunction, saf::MOI.ScalarAffineFunction{T}) where {T<:Real}
    # get the VariableIndexs, convert them to strings and create 
    var_array = IntVarViewMul[]
    for term in saf.terms
        id = term.variable_index.value
        new_id = string(length(keys(model.cpmodel.variables)) + 1)
        push!(var_array, IntVarViewMul(model.cpmodel.variables[id], term.coefficient, new_id))
    end

    # create a new variable with domain defined by min and max of the Linear Combination (CL)
    min = sum([minimum(var.domain) for var in var_array])
    max = sum([maximum(var.domain) for var in var_array])
    new_id = string(length(keys(model.cpmodel.variables)) + 1)
    objective = CPRL.IntVar(min, max, "objective", model.cpmodel.trailer)
    CPRL.addVariable!(model, objective)

    # create a constraint such that objective = linear combination
    minusobjective = CPRL.IntVarViewOpposite(objective, string(parse(Int, new_id) + 1))
    CPRL.addVariable!(model, minusobjective)
    push!(var_array, minusobjective)

    # constraint: a_1*x_1 + ... + a_n*x_n - objective = 0
    constraint = CPRL.SumToZero(var_array, model.cpmodel.trailer)
    push!(model.cpmodel.constraints, constraint)

    # tell the inner model that it is its objective !
    model.cpmodel.objective = objective
end
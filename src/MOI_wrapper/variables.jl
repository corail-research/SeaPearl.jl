
"""
    MOI.add_constrained_variable(model::Optimizer, set::MOI.Interval{Int})

Add a variable to the model, enforcing to give an interval with it as you cannot create variables without bounds in CPRL.
"""
function MOI.add_constrained_variable(model::Optimizer, set::MOI.Interval{Int})
    # create new id
    id = string(length(keys(model.cpmodel.variables)) + 1)

    # get information from the set
    min = set.lower
    max = set.upper

    newvariable = CPRL.IntVar(min, max, id, model.cpmodel.trailer)
    CPRL.addVariable!(model.cpmodel, newvariable)

    return MOI.VariableIndex(parse(Int, id)), MOI.ConstraintIndex{MOI.SingleVariable, MOI.Interval{Int64}}(parse(Int, id))
end
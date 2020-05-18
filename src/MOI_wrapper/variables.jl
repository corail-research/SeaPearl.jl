
"""
MOI.add_constrained_variable(model::Optimizer)

Interface function which add a variable to the model (which is himself an Optimizer)
"""
function MOI.add_constrained_variable(model::Optimizer, set::MOI.Interval)
"""
Might be compulsory to create a new constraint: variable in interval, to create it 
in this function and to throw it at the end (instead of nothing)
"""
# create new id
id = string(length(keys(model.cpmodel.variables)) + 1)

# get information from the set
min = set.lower
max = set.upper

newvariable = CPRL.IntVar(min, max, id, model.cpmodel.trailer)
CPRL.addVariable!(model.cpmodel, newvariable)
return MOI.VariableIndex(parse(Int, id)), nothing
end

# """
#     MOI.add_constrained_variable(model::Optimizer, set::MOI.Interval{Int})

# Add a variable to the model, enforcing to give an interval with it as you cannot create variables without bounds in SeaPearl.
# """

function MOI.add_variable(model::Optimizer)
    id = length(keys(model.moimodel.variables)) + 1

    vi = MOI.VariableIndex(id)

    moiv = MOIVariable("", nothing, nothing, vi)
    push!(model.moimodel.variables, moiv)

    return vi
end
struct NotEqualSet <: MOI.AbstractVectorSet end

function create_CPConstraint(moiconstraint::MOIConstraint{NotEqual}, optimizer::Optimizer)
    id1, id2 = moiconstraint.args
    string1, string2 = optimizer.moimodel.variables[id1].name, optimizer.moimodel.variables[id2].name
    x = optimizer.cpmodel.variables[string1]
    y = optimizer.cpmodel.variables[string2]
    NotEqual(x, y, optimizer.cpmodel.trailer)
end

MOI.dimension(s::NotEqualSet) = 2

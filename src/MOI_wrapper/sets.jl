struct NotEqualSet <: MOI.AbstractVectorSet end

function create_CPConstraint(moiconstraint::MOIConstraint{NotEqualSet}, optimizer::Optimizer)
    id1, id2 = moiconstraint.args
    x, y = get_cp_variable(optimizer, id1), get_cp_variable(optimizer, id2)
    NotEqual(x, y, optimizer.cpmodel.trailer)
end

MOI.dimension(s::NotEqualSet) = 2

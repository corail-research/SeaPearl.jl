struct NotEqualSet <: MOI.AbstractVectorSet end

MOI.dimension(s::NotEqualSet) = 2

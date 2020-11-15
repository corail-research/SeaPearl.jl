struct NotEqualSet <: MOI.AbstractVectorSet end

Base.copy(::NotEqualSet) = NotEqualSet()

MOI.dimension(s::NotEqualSet) = 2

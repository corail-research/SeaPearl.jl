
struct NotEqualTo <: MOI.AbstractScalarSet
    value::Int
end

# if true, variables are equal, else they are different
struct VariablesEquality <: MOI.AbstractVectorSet
    value::Bool

end

MOI.dimension(s::VariablesEquality) = 2

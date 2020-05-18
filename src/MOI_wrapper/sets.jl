
struct NotEqualTo <: MOI.AbstractScalarSet
    value::Int
end

# if true, variables are equal, else they are different
struct VariablesEquality <: MOI.AbstractScalarSet
    value::Bool
end


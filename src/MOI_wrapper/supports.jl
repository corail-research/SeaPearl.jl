"""
    This a list of all the supported variables' creation of CPRL Solver
"""
MOI.supports_add_constrained_variable(::Optimizer, ::Type{MOI.Interval}) = true

"""
    This a list of all the supported constraints of CPRL Solver
"""
function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.SingleVariable}, ::Type{F}
) where {F <: Union{
    MOI.EqualTo, NotEqual
}}
    return true
end

function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.VectorOfVariables}, ::Type{F}
) where {F <: Union{
    VariablesEquality
}}
    return true
end
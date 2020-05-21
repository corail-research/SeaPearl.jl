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
    MOI.EqualTo{Int}, NotEqualTo, MOI.LessThan{Float64}, MOI.GreaterThan{Float64}, MOI.Interval{Float64}
}}
    return true
end

function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.ScalarAffineFunction{Float64}}, ::Type{F}
) where {F <: Union{
    MOI.LessThan{Float64}, MOI.GreaterThan{Float64}
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
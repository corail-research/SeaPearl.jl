"""
    This a list of all the supported variables' creation of CPRL Solver
"""
MOI.supports_add_constrained_variable(::CPRL.Optimizer, ::Type{MOI.Interval}) = true
MOI.supports_add_constrained_variables(::CPRL.Optimizer, ::Type{MOI.Reals}) = false

MOI.supports_constraint(::CPRL.Optimizer, ::Type{MOI.SingleVariable}, ::Type{MOI.Interval{Int64}}) = false


"""
    This a list of all the supported constraints of CPRL Solver
"""
function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.SingleVariable}, ::Type{F}
) where {F <: Union{
    MOI.EqualTo{Int}, NotEqualTo
}}
    return true
end
MOI.supports_constraint(::Optimizer, ::Type{MOI.SingleVariable}, ::MOI.Interval{Int64}) = false

# function MOI.supports_constraint(
#     ::Optimizer, ::Type{MOI.ScalarAffineFunction{Float64}}, ::Type{F}
# ) where {F <: Union{
#     MOI.LessThan{Float64}, MOI.GreaterThan{Float64}
# }}
#     return true
# end

function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.VectorOfVariables}, ::Type{F}
) where {F <: Union{
    VariablesEquality
}}
    return true
end
MOI.supports_constraint(::Optimizer, ::Type{MOI.VectorOfVariables}, ::Type{VariablesEquality}) = true

"""
    This a list of all the supported objective functions of the CPRL Solver
"""
#MOI.supports(::Optimizer, ::MOI.ObjectiveSense) = true
MOI.supports(::Optimizer, ::MOI.ObjectiveFunction{MOI.SingleVariable}) = true
MOI.supports(::Optimizer, ::MOI.ObjectiveFunction{MOI.ScalarAffineFunction{T}}) where {T<:Real} = true
"""
    This a list of all the supported variables' creation of SeaPearl Solver
"""
# MOI.supports_add_constrained_variable(::SeaPearl.Optimizer, ::Type{MOI.Interval{Int64}}) = true
# MOI.supports_add_constrained_variable(::SeaPearl.Optimizer, ::Type{SeaPearl.VariablesEquality}) = false
# MOI.supports_add_constrained_variables(::SeaPearl.Optimizer, ::Type{SeaPearl.VariablesEquality}) = false
# MOI.supports_add_constrained_variables(::SeaPearl.Optimizer, ::Type{MOI.Reals}) = false

# MOI.supports_constraint(::SeaPearl.Optimizer, ::Type{MOI.SingleVariable}, ::Type{MOI.Interval{Int64}}) = true


"""
    This a list of all the supported constraints of SeaPearl Solver
"""
function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.SingleVariable}, ::Type{F}
) where {F <: Union{
    MOI.LessThan{Float64}, MOI.GreaterThan{Float64}
}}
    return true
end
# MOI.supports_constraint(::Optimizer, ::Type{MOI.SingleVariable}, ::MOI.Interval{Int64}) = false

function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.ScalarAffineFunction{Float64}}, ::Type{F}
) where {F <: Union{
    MOI.EqualTo{Float64}, MOI.LessThan{Float64}
}}
    return true
end

function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.VectorOfVariables}, ::Type{F}
) where {F <: Union{
    NotEqualSet
}}
    return true
end

"""
    This a list of all the supported objective functions of the SeaPearl Solver
"""
MOI.supports(::Optimizer, ::MOI.ObjectiveSense) = true
MOI.supports(::Optimizer, ::MOI.ObjectiveFunction{MOI.SingleVariable}) = true
MOI.supports(::Optimizer, ::MOI.ObjectiveFunction{MOI.ScalarAffineFunction{T}}) where {T<:Real} = true
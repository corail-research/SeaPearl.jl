using JuMP

"""
    Utilities for the NotEqualTo extension.
"""
JuMP.sense_to_set(::Function, ::Val{:!=}) = NotEqualTo(0)
MOIU.shift_constant(set::NotEqualTo, value) = NotEqualTo(set.value + value)

"""
        Make sure everything work even when an Int is given to GreaterThan
"""
MOIU.shift_constant(set::MOI.GreaterThan, value::T) where T<:Real = MOI.GreaterThan(set.lower + value)

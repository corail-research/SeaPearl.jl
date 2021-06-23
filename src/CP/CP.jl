using LightGraphs

abstract type Constraint end
abstract type OnePropagationConstraint <: Constraint end

include("variables/variables.jl")
include("core/core.jl")
include("constraints/constraints.jl")
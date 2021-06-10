using LightGraphs

abstract type Constraint end
abstract type OnePropagationConstraint <: Constraint end

include("variables/variables.jl")
include("core/model.jl")
include("constraints/constraints.jl")

include("core/fixPoint.jl")
include("variableselection/variableselection.jl")

include("core/search/strategies.jl")

include("valueselection/valueselection.jl")

include("core/search/search.jl")
include("core/solver.jl")

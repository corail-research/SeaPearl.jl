
abstract type Constraint end

include("variables/variables.jl")
include("core/model.jl")
include("constraints/constraints.jl")

include("valueselection/valueselection.jl")

include("core/fixPoint.jl")

include("core/search/search.jl")
include("core/solver.jl")

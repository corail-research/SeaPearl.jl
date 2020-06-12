
abstract type Constraint end

include("variables/variables.jl")
include("core/model.jl")
include("constraints/constraints.jl")

include("../RL/RL.jl")

include("core/fixPoint.jl")

include("core/search/search.jl")
include("core/solver.jl")

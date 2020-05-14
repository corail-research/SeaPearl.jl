
abstract type Constraint end

include("core/variables.jl")
include("constraints/constraints.jl")
include("core/model.jl")


include("core/fixPoint.jl")

solve() = @info "Solved !"

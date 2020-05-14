
abstract type Constraint end

include("core/variables.jl")
include("constraints/constraints.jl")

solve() = @info "Solved !"

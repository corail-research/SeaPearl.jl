using CPRL
using Random
using GeometricFlux

@testset "RL.jl" begin

    include("representation/representation.jl")
    include("env/env.jl")
    include("nn_structures/nn_structures.jl")
    include("env/reward.jl")
    include("explorers/directed_explorer.jl")

end

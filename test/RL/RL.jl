using CPRL
using Random
using GeometricFlux

@testset "RL.jl" begin

    include("representation/representation.jl")
    include("env/env.jl")
    include("env/reward.jl")
    include("agents/agents.jl")
    include("explorers/directed_explorer.jl")

end

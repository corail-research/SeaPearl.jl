using CPRL
using Random
using GeometricFlux

@testset "RL.jl" begin

    include("representation/cp_layer/cp_layer.jl")
    include("env/spaces/spaces.jl")
    include("env/env.jl")
    include("env/reward.jl")
    include("preprocessor/preprocessor.jl")
    include("agents/agents.jl")
    include("hooks.jl")
    include("stop_conditions.jl")
    include("explorers/directed_explorer.jl")

end

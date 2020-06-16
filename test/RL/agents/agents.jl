using Flux

@testset "agents.jl" begin

    include("nn_structures/nn_structures.jl")

    include("randomagent.jl")
    include("basicdqnagent.jl")
    include("dqnagent.jl")

end
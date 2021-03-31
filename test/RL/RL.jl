using SeaPearl
using Random
using GeometricFlux

@testset "RL.jl" begin

    include("representation/representation.jl")
    include("nn_structures/nn_structures.jl")
    # include("explorers/directed_explorer.jl")
    include("utils.jl")

end

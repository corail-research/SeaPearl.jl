using Random


@testset "RL.jl" begin
    include("representation/representation.jl")
    include("utils/heterogeneousfeaturedgraph.jl")
    include("utils/batchedheterogeneousfeaturedgraph.jl")
    include("nn_structures/nn_structures.jl")
    include("utils.jl")
end
using Flux

@testset "valueselection.jl" begin 

    include("../../RL/RL.jl")
    include("classic/basicheuristic.jl")
    include("learning/learning.jl")
    include("searchmetrics.jl")
end

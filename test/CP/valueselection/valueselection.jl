using Flux

@testset "valueselection.jl" begin 

    include("../../RL/RL.jl")
    include("basicheuristic.jl")
    include("learnedheuristic.jl")

end

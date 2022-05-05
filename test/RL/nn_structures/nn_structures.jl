@testset "nn_structures.jl" begin

    include("cpnn.jl")
    include("fullfeaturedcpnn.jl")
    include("variableoutputcpnn.jl")
    include("geometricflux.jl")
    include("weighted_graph_gat.jl")

end
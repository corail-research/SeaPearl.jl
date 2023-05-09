using SeaPearl
using Test
using LightGraphs
using Flux
using Zygote
using Random
using DataStructures
using ReinforcementLearning
const RL = ReinforcementLearning

@testset "SeaPearl.jl" begin
    # @time begin
    #     println("CP tests")
    #     include("CP/CP.jl")
    # end
    # @time begin
    #     println("datagen tests")
    #     include("datagen/datagen.jl")
    # end
    # @time begin
    #     println("experiment tests")
    #     include("experiment/experiment.jl")
    # end
    # @time begin
    #     println("RL tests")
    #     include("RL/RL.jl")
    # end
    # @time begin
    #     println("trailer tests")
    #     include("trailer.jl")
    # end
    @time begin
        println("parser tests")
        include("parser/parser.jl")
    end
end
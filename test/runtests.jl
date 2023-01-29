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
    include("CP/CP.jl")
    include("datagen/datagen.jl")
    include("experiment/experiment.jl")
    include("RL/RL.jl")
    include("trailer.jl")
    # include("MOI_wrapper/MOI_wrapper.jl")
end

revise_user = "You use Revise, you're efficient in your work, well done ;)" 
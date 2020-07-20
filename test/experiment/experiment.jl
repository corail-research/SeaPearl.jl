@testset "experiment.jl" begin

    include("launch_experiment.jl")
    include("training.jl")
    include("benchmark_solving.jl")
    
end
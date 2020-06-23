using CPRL
using Test

using ReinforcementLearning
const RL = ReinforcementLearning

@testset "CPRL.jl" begin
    include("CP/CP.jl")
    # RL tests are launched in CP/valueselection
    include("MOI_wrapper/MOI_wrapper.jl")
    include("trailer.jl")
    include("datagen/datagen.jl")
    include("training.jl")
end

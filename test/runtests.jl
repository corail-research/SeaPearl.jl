using CPRL
using Test

@testset "CPRL.jl" begin
    include("CP/CP.jl")
    include("RL/RL.jl")
    include("MOI_wrapper/MOI_wrapper.jl")
    include("trailer.jl")
end

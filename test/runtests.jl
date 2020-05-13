using CPRL
using Test

@testset "CPRL.jl" begin
    include("CP/CP.jl")
    include("RL/RL.jl")
    include("MOI/MOI.jl")
end

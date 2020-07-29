using Test
using SeaPearl
@testset "variables.jl" begin
    include("IntDomain.jl")
    include("IntVar.jl")
    include("IntVarView.jl")
end
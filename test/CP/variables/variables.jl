using Test
using SeaPearl
@testset "variables.jl" begin
    include("IntDomain.jl")
    include("IntVar.jl")
    include("IntVarView.jl")
    include("BoolVar.jl")
    include("IntSetDomain.jl")
    include("IntSetVar.jl")
    include("BoolVarView.jl")
end
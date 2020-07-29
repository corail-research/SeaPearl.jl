@testset "optimizer_accessors.jl" begin
    @testset "MOI.get(::Optimizer, ::MOI.SolverName)" begin
        model = SeaPearl.Optimizer()
        @test MOI.get(model, MOI.SolverName()) == "SeaPearl Solver"
    end
end
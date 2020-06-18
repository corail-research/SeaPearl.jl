@testset "optimizer_accessors.jl" begin
    @testset "MOI.get(::Optimizer, ::MOI.SolverName)" begin
        model = CPRL.Optimizer()
        @test MOI.get(model, MOI.SolverName()) == "CPRL Solver"
    end
end
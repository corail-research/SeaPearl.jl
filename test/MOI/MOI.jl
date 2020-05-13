@testset "MOI.jl" begin
    @testset "add_constraint()" begin
        @test CPRL.MOI.add_constraint() == nothing
        @test_logs (:info, "Constraint added !") CPRL.MOI.add_constraint()
    end
end
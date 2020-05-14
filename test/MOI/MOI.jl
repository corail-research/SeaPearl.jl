@testset "MOI.jl" begin
    @testset "add_constraint()" begin
        @test CPRL.add_constraint() == nothing
        @test_logs (:info, "Constraint added !") CPRL.add_constraint()
    end
end
@testset "CP.jl" begin
    @testset "solve()" begin
        @test (@test_logs (:info, "Solved !") CPRL.CP.solve()) == nothing
    end
end
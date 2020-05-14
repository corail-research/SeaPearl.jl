@testset "CP.jl" begin

    include("core/variables.jl")

    @testset "solve()" begin
        @test (@test_logs (:info, "Solved !") CPRL.solve()) == nothing
    end
end
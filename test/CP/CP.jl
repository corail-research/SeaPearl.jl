@testset "CP.jl" begin

    include("variables/variables.jl")
    include("constraints/constraints.jl")
    include("core/model.jl")

    include("core/fixPoint.jl")
    include("core/search/search.jl")

    # @testset "solve()" begin
    #     @test (@test_logs (:info, "Solved !") CPRL.solve()) == nothing
    # end
end
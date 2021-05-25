@testset "CP.jl" begin

    include("variables/variables.jl")
    include("core/model.jl")
    include("constraints/constraints.jl")

    include("core/fixPoint.jl")
    include("core/cpModification.jl")

    include("core/search/strategies.jl")

    include("variableselection/variableselection.jl")

    include("valueselection/valueselection.jl")

    include("core/search/search.jl")
    include("core/solver.jl")

    # @testset "solve()" begin
    #     @test (@test_logs (:info, "Solved !") SeaPearl.solve()) == nothing
    # end
end
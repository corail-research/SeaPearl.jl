@testset "model.jl" begin
    @testset "addVariable!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 6, "y", trailer)

        model = SeaPearl.CPModel(trailer)

        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)

        @test length(model.variables) == 2
        @test SeaPearl.branchable_variables(model) == Dict{String, SeaPearl.AbstractVar}(["x" => x, "y" => y])

        z = SeaPearl.IntVar(2, 6, "y", trailer)

        @test_throws AssertionError SeaPearl.addVariable!(model, z)

        # Not branching
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 6, "y", trailer)

        model = SeaPearl.CPModel(trailer)

        SeaPearl.addVariable!(model, x; branchable=false)
        SeaPearl.addVariable!(model, y)

        @test length(model.variables) == 2
        @test SeaPearl.branchable_variables(model) == Dict{String, SeaPearl.AbstractVar}(["y" => y])

        # Trying to branch on Set variable
        trailer = SeaPearl.Trailer()
        y = SeaPearl.IntSetVar(2, 6, "y", trailer)

        model = SeaPearl.CPModel(trailer)

        @test_throws AssertionError SeaPearl.addVariable!(model, y)
    end

    @testset "merge!()" begin
        test1 = SeaPearl.CPModification("x" => [2, 3, 4],"z" => [11, 12, 13, 14, 15],"y" => [7, 8])
        test2 = SeaPearl.CPModification("x" => [5],"y" => [7, 8])

        SeaPearl.merge!(test1, test2)

        @test test1 == SeaPearl.CPModification("x" => [2, 3, 4, 5],"z" => [11, 12, 13, 14, 15],"y" => [7, 8, 7, 8])
    end

    @testset "addToPrunedDomains!()" begin
        test1 = SeaPearl.CPModification("x" => [2, 3, 4],"z" => [11, 12, 13, 14, 15],"y" => [7, 8])
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        t = SeaPearl.IntVar(2, 6, "t", trailer)
        b = SeaPearl.BoolVar("b", trailer)

        SeaPearl.addToPrunedDomains!(test1, x, [5, 6])

        @test test1 == SeaPearl.CPModification("x" => [2, 3, 4, 5, 6],"z" => [11, 12, 13, 14, 15],"y" => [7, 8])

        SeaPearl.addToPrunedDomains!(test1, t, [5, 6])

        @test test1 == SeaPearl.CPModification("x" => [2, 3, 4, 5, 6],"z" => [11, 12, 13, 14, 15],"y" => [7, 8], "t" => [5, 6])

        SeaPearl.addToPrunedDomains!(test1, b, [true])

        @test test1 == SeaPearl.CPModification("x" => [2, 3, 4, 5, 6],"z" => [11, 12, 13, 14, 15],"y" => [7, 8], "t" => [5, 6], "b" => [true])

    end

    @testset "solutionFound()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 6, "y", trailer)

        model = SeaPearl.CPModel(trailer)

        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)

        @test !SeaPearl.solutionFound(model)

        constraint = SeaPearl.EqualConstant(x, 3, trailer)
        constraint2 = SeaPearl.Equal(x, y, trailer)
        push!(model.constraints, constraint)
        push!(model.constraints, constraint2)

        SeaPearl.fixPoint!(model)

        @test SeaPearl.solutionFound(model)
    end

    @testset "triggerFoundSolution!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(3, 3, "y", trailer)

        model = SeaPearl.CPModel(trailer)

        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addObjective!(model, y)

        SeaPearl.triggerFoundSolution!(model)

        @test length(model.statistics.solutions) == 1
        @test model.statistics.solutions[1] == Dict("x" => 2,"y" => 3)
        @test model.objectiveBound == 2
        @test model.statistics.numberOfSolutions == 1
        @test model.statistics.objectives[1] == 3

    end

    @testset "tightenObjective!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(3, 3, "y", trailer)

        model = SeaPearl.CPModel(trailer)

        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addObjective!(model, y)

        @test isnothing(model.objectiveBound)


        SeaPearl.tightenObjective!(model)

        @test model.objectiveBound == 2
    end

    @testset "belowLimits()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        model.statistics.numberOfNodes = 1500
        model.statistics.numberOfSolutions = 15

        @test SeaPearl.belowLimits(model)

        model.limit.numberOfNodes = 1501
        model.limit.numberOfSolutions = 16
        @test SeaPearl.belowLimits(model)

        model.statistics.numberOfNodes = 1501
        @test !SeaPearl.belowLimits(model)

        model.statistics.numberOfNodes = 1500
        model.statistics.numberOfSolutions = 16
        @test !SeaPearl.belowLimits(model)
    end

    @testset "belowNodeLimit()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        model.statistics.numberOfNodes = 1500

        @test SeaPearl.belowNodeLimit(model)

        model.limit.numberOfNodes = 1501
        @test SeaPearl.belowNodeLimit(model)

        model.statistics.numberOfNodes = 1501
        @test !SeaPearl.belowNodeLimit(model)
    end

    @testset "belowSolutionLimits()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        model.statistics.numberOfSolutions = 15

        @test SeaPearl.belowSolutionLimit(model)

        model.limit.numberOfSolutions = 16
        @test SeaPearl.belowSolutionLimit(model)

        model.statistics.numberOfSolutions = 16
        @test !SeaPearl.belowSolutionLimit(model)
    end

    @testset "Base.isempty()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        @test isempty(model)

        x = SeaPearl.IntVar(2, 2, "x", trailer)
        SeaPearl.addVariable!(model, x)

        @test !isempty(model)
    end

    @testset "Base.empty!()" begin

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 2, "x", trailer)
        SeaPearl.addVariable!(model, x)

        empty!(model)

        @test isempty(model)
    end

    @testset "reset_model!()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 5, "x", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.assign!(x, 3)

        @test SeaPearl.length(x.domain) == 1
        SeaPearl.reset_model!(model)
        @test SeaPearl.length(x.domain) == 4
    end
end

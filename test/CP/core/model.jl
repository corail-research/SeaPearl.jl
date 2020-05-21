@testset "model.jl" begin
    @testset "addVariable!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        y = CPRL.IntVar(2, 6, "y", trailer)

        model = CPRL.CPModel(trailer)

        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)

        @test length(model.variables) == 2

        z = CPRL.IntVar(2, 6, "y", trailer)

        @test_throws AssertionError CPRL.addVariable!(model, z)
    end

    @testset "merge!()" begin
        test1 = CPRL.CPModification("x" => [2, 3, 4],"z" => [11, 12, 13, 14, 15],"y" => [7, 8])
        test2 = CPRL.CPModification("x" => [5],"y" => [7, 8])

        CPRL.merge!(test1, test2)

        @test test1 == CPRL.CPModification("x" => [2, 3, 4, 5],"z" => [11, 12, 13, 14, 15],"y" => [7, 8, 7, 8])
    end

    @testset "addToPrunedDomains!()" begin
        test1 = CPRL.CPModification("x" => [2, 3, 4],"z" => [11, 12, 13, 14, 15],"y" => [7, 8])
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        t = CPRL.IntVar(2, 6, "t", trailer)

        CPRL.addToPrunedDomains!(test1, x, [5, 6])

        @test test1 == CPRL.CPModification("x" => [2, 3, 4, 5, 6],"z" => [11, 12, 13, 14, 15],"y" => [7, 8])

        CPRL.addToPrunedDomains!(test1, t, [5, 6])

        @test test1 == CPRL.CPModification("x" => [2, 3, 4, 5, 6],"z" => [11, 12, 13, 14, 15],"y" => [7, 8], "t" => [5, 6])
    end

    @testset "solutionFound()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        y = CPRL.IntVar(2, 6, "y", trailer)

        model = CPRL.CPModel(trailer)

        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)

        @test !CPRL.solutionFound(model)

        constraint = CPRL.EqualConstant(x, 3, trailer)
        constraint2 = CPRL.Equal(x, y, trailer)
        push!(model.constraints, constraint)
        push!(model.constraints, constraint2)

        CPRL.fixPoint!(model)

        @test CPRL.solutionFound(model)
    end

    @testset "triggerFoundSolution!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 2, "x", trailer)
        y = CPRL.IntVar(3, 3, "y", trailer)

        model = CPRL.CPModel(trailer)

        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        model.objective = y

        CPRL.triggerFoundSolution!(model)

        @test length(model.solutions) == 1
        @test model.solutions[1] == Dict("x" => 2,"y" => 3)
        @test length(model.constraints) == 1
        @test model.constraints[1].v == 2
        @test model.constraints[1].x == y
        @test isa(model.constraints[1], CPRL.LessOrEqualConstant)
    end

    @testset "tightenObjective!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 2, "x", trailer)
        y = CPRL.IntVar(3, 3, "y", trailer)

        model = CPRL.CPModel(trailer)

        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        model.objective = y

        CPRL.tightenObjective!(model)

        @test length(model.constraints) == 1
        @test model.constraints[1].v == 2
        @test model.constraints[1].x == y
        @test isa(model.constraints[1], CPRL.LessOrEqualConstant)
    end

    @testset "belowLimits()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        model.statistics.numberOfNodes = 1500
        model.statistics.numberOfSolutions = 15

        @test CPRL.belowLimits(model)

        model.limit.numberOfNodes = 1501
        model.limit.numberOfSolutions = 16
        @test CPRL.belowLimits(model)

        model.statistics.numberOfNodes = 1501
        @test !CPRL.belowLimits(model)

        model.statistics.numberOfNodes = 1500
        model.statistics.numberOfSolutions = 16
        @test !CPRL.belowLimits(model)
    end
end
@testset "evaluation.jl" begin

    @testset "SameInstancesEvaluator constructor" begin
        generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)

        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)
        valueSelectionArray = [valueheuristic]

        evaluator = SeaPearl.SameInstancesEvaluator(valueSelectionArray, generator; evalFreq=50, nbInstances=2)

        @test evaluator.nbInstances == 2
        @test evaluator.evalFreq == 50
        @test length(evaluator.instances) == 2
        @test length(values(evaluator.instances[1].variables)) == 11
        @test length(values(evaluator.instances[2].variables)) == 11

        evaluator = SeaPearl.SameInstancesEvaluator(valueSelectionArray, generator; evalFreq=0, nbInstances=2)

        @test evaluator.evalFreq == 1   #ensure that if evalFreq is less than 1, the model will be evaluated at each learning episode
    end

    @testset "evaluate(::SameInstancesEvaluator)" begin

        generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)

        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)
        valueSelectionArray = [valueheuristic]
        rng = MersenneTwister()
        Random.seed!(rng, 1)
        evaluator = SeaPearl.SameInstancesEvaluator(valueSelectionArray, generator; rng=rng, evalFreq=50, nbInstances=2)

        variableheuristic = SeaPearl.MinDomainVariableSelection{false}()

        SeaPearl.evaluate(evaluator, variableheuristic, SeaPearl.DFSearch())
        @test evaluator.metrics[1, 1].nodeVisited[1] == [12, 23]
    end

    @testset "empty!(eval::SameInstancesEvaluator)" begin

        generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)

        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)
        valueSelectionArray = [valueheuristic]
        rng = MersenneTwister()
        Random.seed!(rng, 1)
        evaluator = SeaPearl.SameInstancesEvaluator(valueSelectionArray, generator; rng=rng, evalFreq=50, nbInstances=1)

        variableheuristic = SeaPearl.MinDomainVariableSelection{false}()

        SeaPearl.evaluate(evaluator, variableheuristic, SeaPearl.DFSearch())
        @test evaluator.metrics[1, 1].nbEpisodes == 1
        @test !isempty(evaluator.metrics[1, 1].nodeVisited)
        @test !isempty(evaluator.metrics[1, 1].meanNodeVisitedUntilfirstSolFound)
        @test !isempty(evaluator.metrics[1, 1].meanNodeVisitedUntilEnd)
        @test !isempty(evaluator.metrics[1, 1].timeneeded)
        @test !isempty(evaluator.metrics[1, 1].scores)
        @test !isempty(evaluator.metrics[1, 1].timeneeded)

        SeaPearl.empty!(evaluator)
        @test evaluator.metrics[1, 1].nbEpisodes == 0
        @test isempty(evaluator.metrics[1, 1].nodeVisited)
        @test isempty(evaluator.metrics[1, 1].meanNodeVisitedUntilfirstSolFound)
        @test isempty(evaluator.metrics[1, 1].meanNodeVisitedUntilEnd)
        @test isempty(evaluator.metrics[1, 1].timeneeded)
        @test isempty(evaluator.metrics[1, 1].scores)
        @test isempty(evaluator.metrics[1, 1].timeneeded)
    end
end
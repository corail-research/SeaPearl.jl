@testset "evaluation.jl" begin

    @testset "SameInstancesEvaluator constructor" begin
        generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)
       
        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)
        valueSelectionArray = [valueheuristic]
        evaluator = SeaPearl.SameInstancesEvaluator(valueSelectionArray,generator; seed=nothing, evalFreq = 50, nbInstances = 2)


        @test evaluator.nbInstances == 2
        @test evaluator.evalFreq == 50
        @test length(evaluator.instances) == 2
        @test length(values(evaluator.instances[1].variables)) == 11
        @test length(values(evaluator.instances[2].variables)) == 11

        evaluator = SeaPearl.SameInstancesEvaluator(valueSelectionArray,generator; seed=nothing, evalFreq = 0, nbInstances = 2)

        @test evaluator.evalFreq == 1   #ensure that if evalFreq is less than 1, the model will be evaluated at each learning episode
    end

    @testset "evaluate(::SameInstancesEvaluator)" begin
        
        generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)
        
        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)
        valueSelectionArray = [valueheuristic]
        evaluator = SeaPearl.SameInstancesEvaluator(valueSelectionArray,generator; seed=1, evalFreq = 50, nbInstances = 2)

        variableheuristic = SeaPearl.MinDomainVariableSelection{false}()

        SeaPearl.evaluate(evaluator, variableheuristic, SeaPearl.DFSearch())
        @test evaluator.metrics[1,1].nodeVisited[1] == [12, 23]
    end
end
@testset "evaluation.jl" begin

    @testset "SameInstancesEvaluator constructor" begin
        generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)
       
        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)
        valueSelectionArray = [valueheuristic]
        evaluator = SeaPearl.SameInstancesEvaluator(valueSelectionArray,generator; seed=nothing, eval_freq = 50, nb_instances = 2)


        @test evaluator.nb_instances == 2
        @test evaluator.eval_freq == 50
        @test length(evaluator.instances) == 2
        @test length(values(evaluator.instances[1].variables)) == 11
        @test length(values(evaluator.instances[2].variables)) == 11
    end

    @testset "evaluate(::SameInstancesEvaluator)" begin
        
        generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)
        
        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)
        valueSelectionArray = [valueheuristic]
        evaluator = SeaPearl.SameInstancesEvaluator(valueSelectionArray,generator; seed=nothing, eval_freq = 50, nb_instances = 2)

        variableheuristic = SeaPearl.MinDomainVariableSelection{false}()

        SeaPearl.evaluate(evaluator, variableheuristic, SeaPearl.DFSearch)
        @test evaluator.metrics[1,1].NodeVisited[1] == [12]
    end
end
@testset "evaluation.jl" begin
    @testset "SameInstancesEvaluator constructor" begin
        eval = SeaPearl.SameInstancesEvaluator()

        @test eval.nb_instances == 50
        @test eval.eval_freq == 50
        @test isnothing(eval.instances)
    end

    @testset "init_evaluator!(::SameInstancesEvaluator)" begin
        eval = SeaPearl.SameInstancesEvaluator(; nb_instances = 2)
        generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)


        SeaPearl.init_evaluator!(eval, generator)

        @test length(eval.instances) == 2
        @test length(values(eval.instances[1].variables)) == 11
        @test length(values(eval.instances[2].variables)) == 11
    end

    @testset "evaluate(::SameInstancesEvaluator)" begin
        
        eval = SeaPearl.SameInstancesEvaluator(; nb_instances = 2)
        generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)
        SeaPearl.init_evaluator!(eval, generator; seed=8)

        variableheuristic = SeaPearl.MinDomainVariableSelection{false}()
        my_heuristic(x::SeaPearl.IntVar) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)

        nodes, dtime = SeaPearl.evaluate(eval, variableheuristic, valueheuristic, SeaPearl.DFSearch)
        @test nodes == 23.
    end
end
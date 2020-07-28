@testset "evaluation.jl" begin
    @testset "SameInstancesEvaluator constructor" begin
        eval = CPRL.SameInstancesEvaluator()

        @test eval.nb_instances == 50
        @test eval.eval_freq == 50
        @test isnothing(eval.instances)
    end

    @testset "init_evaluator!(::SameInstancesEvaluator)" begin
        eval = CPRL.SameInstancesEvaluator(; nb_instances = 2)
        generator = CPRL.HomogenousGraphColoringGenerator(10, 0.1)


        CPRL.init_evaluator!(eval, generator)

        @test length(eval.instances) == 2
        @test length(values(eval.instances[1].variables)) == 11
        @test length(values(eval.instances[2].variables)) == 11
    end

    @testset "evaluate(::SameInstancesEvaluator)" begin
        
        eval = CPRL.SameInstancesEvaluator(; nb_instances = 2)
        generator = CPRL.HomogenousGraphColoringGenerator(10, 0.1)
        CPRL.init_evaluator!(eval, generator; rng=MersenneTwister(8))

        variableheuristic = CPRL.MinDomainVariableSelection{false}()
        my_heuristic(x::CPRL.IntVar) = minimum(x.domain)
        valueheuristic = CPRL.BasicHeuristic(my_heuristic)

        nodes, dtime = CPRL.evaluate(eval, variableheuristic, valueheuristic, CPRL.DFSearch)
        @test nodes == 23.
    end
end
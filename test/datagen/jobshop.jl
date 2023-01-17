@testset "jobshop.jl" begin
    @testset "fill_with_generator!(::JobShopGenerator)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        num_machines = 2
        num_jobs = 3
        max_time = 4
        generator = SeaPearl.JobShopGenerator(num_machines, num_jobs, max_time)
        rng = MersenneTwister()
        Random.seed!(rng, 12)
        SeaPearl.fill_with_generator!(model, generator; rng=rng)

        @test length(keys(model.variables)) == num_machines * num_jobs + 1
        @test length(model.constraints) == num_machines * num_jobs * 2 + num_jobs + num_machines + num_jobs

        model1 = SeaPearl.CPModel(trailer)
        model2 = SeaPearl.CPModel(trailer)
        model3 = SeaPearl.CPModel(trailer)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model1, generator; rng=rng)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model2, generator; rng=rng)

        rng = MersenneTwister(14)
        SeaPearl.fill_with_generator!(model3, generator; rng=rng)

        @test model1.constraints[2].x.id == model2.constraints[2].x.id
        @test model1.constraints[1].x.id == model3.constraints[1].x.id
    end

    @testset "fill_with_generator!(::JobShopSoftDeadlinesGenerator)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        num_machines = 2
        num_jobs = 3
        max_time = 4
        generator = SeaPearl.JobShopSoftDeadlinesGenerator(num_machines, num_jobs, max_time)
        rng = MersenneTwister()
        Random.seed!(rng, 12)
        SeaPearl.fill_with_generator!(model, generator; rng=rng)

        @test length(keys(model.variables)) == num_machines * num_jobs + num_jobs * 3 + 1
        @test length(model.constraints) == 21

        model1 = SeaPearl.CPModel(trailer)
        model2 = SeaPearl.CPModel(trailer)
        model3 = SeaPearl.CPModel(trailer)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model1, generator; rng=rng)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model2, generator; rng=rng)

        rng = MersenneTwister(14)
        SeaPearl.fill_with_generator!(model3, generator; rng=rng)

        @test model1.constraints[2].x.id == model2.constraints[2].x.id
        @test model1.constraints[1].x.id == model3.constraints[1].x.id
    end

    @testset "fill_with_generator!(::JobShopSoftDeadlinesGenerator2)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        num_machines = 2
        num_jobs = 3
        max_time = 4
        generator = SeaPearl.JobShopSoftDeadlinesGenerator2(num_machines, num_jobs, max_time)
        rng = MersenneTwister()
        Random.seed!(rng, 12)
        SeaPearl.fill_with_generator!(model, generator; rng=rng)

        @test length(keys(model.variables)) == 28
        @test length(model.constraints) == 34

        model1 = SeaPearl.CPModel(trailer)
        model2 = SeaPearl.CPModel(trailer)
        model3 = SeaPearl.CPModel(trailer)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model1, generator; rng=rng)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model2, generator; rng=rng)

        rng = MersenneTwister(14)
        SeaPearl.fill_with_generator!(model3, generator; rng=rng)

        @test model1.constraints[2].x.id == model2.constraints[2].x.id
        @test model1.constraints[1].x.id == model3.constraints[1].x.id
    end
end
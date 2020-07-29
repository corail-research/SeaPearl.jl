using Random
using Flux
using Distributions: Categorical

@testset "directed_explorer.jl" begin
    @testset "DirectedExplorer constructors" begin
        function dummyDirection(values, mask)
            nothing
        end

        trueExplorer = SeaPearl.CPEpsilonGreedyExplorer(
            ϵ_stable = 0.001,
            kind = :exp,
            ϵ_init = 0.1,
            warmup_steps = 0,
            decay_steps = 100,
            step = 1,
            is_break_tie = false, 
            is_training = false
        )

        explorer = SeaPearl.DirectedExplorer(;
            explorer = trueExplorer,
            direction = dummyDirection,
            directed_steps=1234,
            step = 5,
            is_training = false,
            seed = 4321
        )

        @test isa(explorer, SeaPearl.DirectedExplorer{MersenneTwister})
        @test explorer.explorer == trueExplorer
        @test explorer.direction == dummyDirection
        @test explorer.directed_steps == 1234
        @test explorer.step == 5
        @test !explorer.is_training
        @test explorer.rng == MersenneTwister(4321)

        # Default values
        explorer = SeaPearl.DirectedExplorer(trueExplorer, dummyDirection; seed = 12)
        @test isa(explorer, SeaPearl.DirectedExplorer{MersenneTwister})
        @test explorer.explorer == trueExplorer
        @test explorer.direction == dummyDirection
        @test explorer.directed_steps == 100
        @test explorer.step == 1
        @test explorer.is_training
        @test explorer.rng == MersenneTwister(12)
    end
    @testset "Flux.testmode!()" begin
        trueExplorer = SeaPearl.CPEpsilonGreedyExplorer(
            ϵ_stable = 0.001,
            kind = :exp,
            ϵ_init = 0.1,
            warmup_steps = 0,
            decay_steps = 100,
            step = 1,
            is_break_tie = false, 
            is_training = false,
        )

        explorer = SeaPearl.DirectedExplorer(;
            explorer = trueExplorer,
            direction = () -> nothing,
            directed_steps=1234,
            step = 5,
            is_training = false,
            seed = 4321
        )

        Flux.testmode!(explorer, false)
        @test explorer.is_training
        @test trueExplorer.is_training

        Flux.testmode!(explorer)
        @test !explorer.is_training
        @test !trueExplorer.is_training
    end

    @testset "explorer(values)" begin

        function dummyDirection2(values)
            4
        end

        trueExplorer = SeaPearl.CPEpsilonGreedyExplorer(
            ϵ_stable = 0.01,
            kind = :exp,
            ϵ_init = 0.1,
            warmup_steps = 0,
            decay_steps = 100,
            step = 1,
            is_break_tie = false, 
            is_training = true,
            seed = 5
        )

        explorer = SeaPearl.DirectedExplorer(;
            explorer = trueExplorer,
            direction = dummyDirection2,
            directed_steps=1234,
            step = 5,
            is_training = true,
            seed = 4321
        )

        values = Float32[0.1, 0.5, 0.4, 0.]
        @test explorer(values) == 4
        @test explorer.step == 6
        
        Flux.testmode!(explorer)
        @test explorer(values) == 4
        @test explorer.step == 6

        Flux.testmode!(explorer, false)
        @test explorer(values) == 4
        @test explorer.step == 7

        explorer.step = 1235
        @test explorer(values) == 2
        @test trueExplorer.step == 2
    end

    @testset "explorer(values, mask)" begin

        function dummyDirection3(values, mask)
            3
        end

        trueExplorer = SeaPearl.CPEpsilonGreedyExplorer(
            ϵ_stable = 0.01,
            kind = :exp,
            ϵ_init = 0.1,
            warmup_steps = 0,
            decay_steps = 100,
            step = 1,
            is_break_tie = false, 
            is_training = true,
            seed = 5
        )

        explorer = SeaPearl.DirectedExplorer(;
            explorer = trueExplorer,
            direction = dummyDirection3,
            directed_steps=1234,
            step = 5,
            is_training = true,
            seed = 4321
        )

        values = Float32[0.1, 0.5, 0.4, 0., 0.]
        mask = Int[4]
        @test explorer(values, mask) == 3
        @test explorer.step == 6
        
        Flux.testmode!(explorer)
        @test explorer(values, mask) == 3
        @test explorer.step == 6

        Flux.testmode!(explorer, false)
        @test explorer(values, mask) == 3
        @test explorer.step == 7

        explorer.step = 1235
        @test explorer(values, mask) == 4
        @test trueExplorer.step == 2
    end

    @testset "get_prob(exp, values)" begin

        function dummyDirection4(values)
            3
        end

        trueExplorer = SeaPearl.CPEpsilonGreedyExplorer(
            ϵ_stable = 0.01,
            kind = :exp,
            ϵ_init = 0.5,
            warmup_steps = 0,
            decay_steps = 100,
            step = 1,
            is_break_tie = false, 
            is_training = false,
            seed = 5
        )

        explorer = SeaPearl.DirectedExplorer(;
            explorer = trueExplorer,
            direction = dummyDirection4,
            directed_steps=1234,
            step = 5,
            is_training = true,
            seed = 4321
        )

        values = Float32[0.1, 0.5, 0.4, 0., 0.]
        @test SeaPearl.get_prob(explorer, values) == Categorical(Float64[0., 0., 1., 0., 0.])
        
        explorer.step = 1235
        @test SeaPearl.get_prob(explorer, values) == Categorical(Float64[0., 1., 0., 0., 0.])
    end

    @testset "get_prob(exp, values, action)" begin

        function dummyDirection5(values)
            3
        end

        trueExplorer = SeaPearl.CPEpsilonGreedyExplorer(
            ϵ_stable = 0.01,
            kind = :exp,
            ϵ_init = 0.5,
            warmup_steps = 0,
            decay_steps = 100,
            step = 1,
            is_break_tie = false, 
            is_training = false,
            seed = 5
        )

        explorer = SeaPearl.DirectedExplorer(;
            explorer = trueExplorer,
            direction = dummyDirection5,
            directed_steps=1234,
            step = 5,
            is_training = true,
            seed = 4321
        )

        values = Float32[0.1, 0.5, 0.4, 0., 0.]
        @test [SeaPearl.get_prob(explorer, values, i) for i in 1:5] == Float64[0., 0., 1., 0., 0.]
        
        explorer.step = 1235
        @test [SeaPearl.get_prob(explorer, values, i) for i in 1:5] == Float64[0., 1., 0., 0., 0.]
    end

    @testset "get_prob(exp, values, mask)" begin

        function dummyDirection6(values, mask)
            3
        end

        trueExplorer = SeaPearl.CPEpsilonGreedyExplorer(
            ϵ_stable = 0.01,
            kind = :exp,
            ϵ_init = 0.5,
            warmup_steps = 0,
            decay_steps = 100,
            step = 1,
            is_break_tie = false, 
            is_training = false,
            seed = 5
        )

        explorer = SeaPearl.DirectedExplorer(;
            explorer = trueExplorer,
            direction = dummyDirection6,
            directed_steps=1234,
            step = 5,
            is_training = true,
            seed = 4321
        )

        values = Float32[0.1, 0.5, 0.4, 0., 0.]
        mask = Int[1, 4, 5]
        @test SeaPearl.get_prob(explorer, values, mask) == Categorical(Float64[0., 0., 1., 0., 0.])
        
        explorer.step = 1235
        @test SeaPearl.get_prob(explorer, values, mask) == Categorical(Float64[1., 0., 0., 0., 0.])
    end
end
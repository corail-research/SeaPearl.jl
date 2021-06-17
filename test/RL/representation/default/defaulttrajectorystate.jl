@testset "defaulttrajectorystate.jl" begin
    
    @testset "DefaultTrajectoryState" begin
        graph = Matrix(adjacency_matrix(random_regular_graph(6,3)))
        ts1 = SeaPearl.DefaultTrajectoryState(
            GeometricFlux.FeaturedGraph(graph; nf=rand(3,6)),
            2,
            collect(3:6)
        )
        ts2 = SeaPearl.DefaultTrajectoryState(
            GeometricFlux.FeaturedGraph(graph; nf=rand(3,6)),
            2
        )

        batched1 = ts1 |> cpu
        batched2 = ts2 |> cpu
        @test isa(batched1, SeaPearl.BatchedDefaultTrajectoryState{Float32})

        @test all(ts1.fg.graph .== batched1.fg.graph[:, :, 1])
        @test all(abs.(ts1.fg.nf .- batched1.fg.nf[:,:,1]) .< 1e-5)
        @test ts1.variableIdx == batched1.variableIdx[1]
        @test all(ts1.allValuesIdx .==  batched1.allValuesIdx[:,1])

        @test isnothing(batched2.allValuesIdx)
        @test all(ts2.fg.graph .== batched2.fg.graph[:, :, 1])
        @test all(abs.(ts2.fg.nf .- batched2.fg.nf[:,:,1]) .< 1e-5)
        @test ts2.variableIdx == batched2.variableIdx[1]
    end

    @testset "BatchedFeaturedGraph" begin
        graph = cat(Matrix.(adjacency_matrix.([random_regular_graph(6,3) for i =1:3]))...; dims=3)
        nf = rand(4, 6, 3)
        ef = rand(2, 9, 3)
        gf = rand(2, 3)

        batched1 = SeaPearl.BatchedFeaturedGraph(graph, nf, ef, gf)

        @test isa(batched1, SeaPearl.BatchedFeaturedGraph{Float32})

        batched2 = SeaPearl.BatchedFeaturedGraph{Float32}(graph)

        @test size(batched2.graph) == (6,6,3)
        @test size(batched2.nf) == (0,6,3)
        @test size(batched2.ef) == (0,9,3)
        @test size(batched2.gf) == (0,3)
    end

    @testset "BatchedDefaultTrajectoryState" begin
        graph = cat(Matrix.(adjacency_matrix.([random_regular_graph(6, i) for i = 2:4]))...; dims=3)
        bfg = SeaPearl.BatchedFeaturedGraph{Float32}(graph)
        var = collect(1:3)
        val = rand(1:6, 2, 3)

        batched = SeaPearl.BatchedDefaultTrajectoryState(bfg, var, val)

        @test isa(batched, SeaPearl.BatchedDefaultTrajectoryState{Float32})

        batched = SeaPearl.BatchedDefaultTrajectoryState{Float32}(fg=bfg, variableIdx=var)

        @test isnothing(batched.allValuesIdx)
    end

    # TODO test Flux.functor(::Type{Vector{DefaultTrajectoryState}}, v)
    @testset "Flux.functor(::Type{Vector{DefaultTrajectoryState}}, v)" begin
        
    end
end
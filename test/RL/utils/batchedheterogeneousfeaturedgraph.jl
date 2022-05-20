@testset "BatchedBatchedHeterogeneousFeaturedGraph{Float64}" begin 
    @testset "check dimensions" begin 
        #Here we are considering a batch of two identic samples
        #trying to pass symmetric type-specific adjacency matrix
        contovar = cat([0 1 1; 1 0 0; 1 0 0], [0 1 1; 1 0 0; 1 0 0], dims=3)
        valtovar = cat([0 0 1 1 0; 0 0 0 1 1; 1 0 0 0 0; 1 1 0 0 0; 0 1 0 0 0], [0 0 1 1 0; 0 0 0 1 1; 1 0 0 0 0; 1 1 0 0 0; 0 1 0 0 0],dims= 3)
        varnf = rand(4, 2, 2)
        connf = rand(4, 1, 2)
        valnf = rand(4, 3, 2)
        gf = rand(3, 2)

        @test_throws AssertionError SeaPearl.BatchedHeterogeneousFeaturedGraph{Float64}(contovar, valtovar, varnf, connf, valnf, gf)  

        #edefining the type-specific matrix the proper way
        contovar = cat([1 1], [1 1], dims=3)
        valtovar = cat([1 0; 1 1; 0 1], [1 0; 1 1; 0 1], dims= 3)

        @test_throws AssertionError SeaPearl.BatchedHeterogeneousFeaturedGraph{Float64}(contovar, valtovar, varnf, rand(4, 2, 2), valnf, gf)  #unconsistency test (2 constraints instead of 1)
        @test_throws AssertionError SeaPearl.BatchedHeterogeneousFeaturedGraph{Float64}(contovar, valtovar, rand(4, 3, 2), connf, valnf, gf)  #unconsistency test (3 variables instead of 2)
        @test_throws AssertionError SeaPearl.BatchedHeterogeneousFeaturedGraph{Float64}(contovar, valtovar, varnf, connf, rand(4, 2, 2), gf)  #unconsistency test (2 values instead of 3)

    end 

    @testset "accessors" begin 
        contovar = cat([1 1], [1 1], dims=3)
        valtovar = cat([1 0; 1 1; 0 1], [1 0; 1 1; 0 1], dims= 3)

        varnf = rand(4, 2, 2)
        connf = rand(4, 1, 2)
        valnf = rand(4, 3, 2)
        gf = rand(3, 2)
        hfg = SeaPearl.BatchedHeterogeneousFeaturedGraph{Float64}(contovar, valtovar, varnf, connf, valnf, gf)

        @test SeaPearl.variable_node_feature(hfg) == varnf
        @test SeaPearl.constraint_node_feature(hfg) == connf
        @test SeaPearl.value_node_feature(hfg) == valnf

        @test SeaPearl.n_variable_node(hfg) == [2,2]
        @test SeaPearl.n_constraint_node(hfg) == [1,1]
        @test SeaPearl.n_value_node(hfg) == [3,3]

        @test SeaPearl.global_feature(hfg) == gf
    end 

    @testset "BatchedHeterogeneousFeaturedGraph{T}(fgs::Vector{FG}) " begin 
        #TODO add test so check that matrices are padded the right way
    end 

end 
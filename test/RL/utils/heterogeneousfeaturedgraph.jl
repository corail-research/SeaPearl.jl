@testset "HeterogeneousFeaturedGraph" begin 
    @testset "check dimensions" begin 
        #trying to pass symmetric type-specific adjacency matrix
        contovar = Matrix([0 1 1
                        1 0 0
                        1 0 0])
        valtovar = Matrix([0 0 1 1 0
                        0 0 0 1 1
                        1 0 0 0 0
                        1 1 0 0 0
                        0 1 0 0 0])
        varnf = rand(4, 2)
        connf = rand(4, 1)
        valnf = rand(4, 3)
        gf = rand(3)

        @test_throws AssertionError SeaPearl.HeterogeneousFeaturedGraph(contovar, valtovar, varnf, connf, valnf, gf)  

        @test_throws MethodError SeaPearl.HeterogeneousFeaturedGraph(reshape(contovar,3,3,1), valtovar, varnf, connf, valnf, gf)  #the constructor doesn't even allow the object to be constructed
        @test_throws MethodError SeaPearl.HeterogeneousFeaturedGraph(contovar, reshape(valtovar,5,5,1), varnf, connf, valnf, gf)  #the constructor doesn't even allow the object to be constructed
        
        contovar = Matrix([1 1])
        valtovar = Matrix([1 0
                        1 1
                        0 1])
        @test_throws AssertionError SeaPearl.HeterogeneousFeaturedGraph(contovar, valtovar, varnf, rand(4, 2), valnf, gf)  #unconsistency test
        @test_throws AssertionError SeaPearl.HeterogeneousFeaturedGraph(contovar, valtovar, rand(4, 3), connf, valnf, gf)  #unconsistency test
        @test_throws AssertionError SeaPearl.HeterogeneousFeaturedGraph(contovar, valtovar, varnf, connf, rand(4, 2), gf)  #unconsistency test
    end 

    @testset "accessors" begin 
        contovar = Matrix([1 1])
        valtovar = Matrix([1 0
                        1 1
                        0 1])
        varnf = rand(4, 2)
        connf = rand(4, 1)
        valnf = rand(4, 3)
        gf = rand(3)
        hfg = SeaPearl.HeterogeneousFeaturedGraph(contovar, valtovar, varnf, connf, valnf, gf)

        @test SeaPearl.variable_node_feature(hfg) == varnf
        @test SeaPearl.constraint_node_feature(hfg) == connf
        @test SeaPearl.value_node_feature(hfg) == valnf

        @test SeaPearl.n_variable_node(hfg) == 2
        @test SeaPearl.n_constraint_node(hfg) == 1
        @test SeaPearl.n_value_node(hfg) == 3

        @test SeaPearl.global_feature(hfg) == gf
    end 

end 
@testset "tsptwstaterepresentation.jl" begin
    @testset "Constructor" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n_city = 3
        grid_size = 10
        max_tw_gap = 3
        max_tw = 8

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        SeaPearl.fill_with_generator!(model, generator; seed=42)

        dist, timeWindows, pos = model.adhocInfo

        # This condition is there because of the way random are generated can change from one version to another
        if VERSION == v"1.6.0"
            @test dist ==  [0 8 10; 
                            8 0 4; 
                            10 4 0]
            @test timeWindows == [0 10; 8 16; 12 15]
            @test pos == [5.331830160438614 1.7293302893695128; 4.540291355871425 9.589258763297348; 0.17686826714964354 9.735659798036858]
            
            sr = SeaPearl.TsptwStateRepresentation(model)

            @test sr.dist == [  0.0 0.8 1.0
                                0.8 0.0 0.4
                                1.0 0.4 0.0]
            @test trunc.(sr.timeWindows; digits=2) == [0.0  0.62
                                                        0.5 1.0
                                                        0.75 0.93]
            @test trunc.(sr.pos; digits=2) == [ 0.53 0.17
                                                0.45 0.95
                                                0.01 0.97]
            @test trunc.(sr.nodeFeatures; digits=2) == transpose(Float32[0.53 0.17 0.0 0.62 0.0 0.0; 0.45 0.95 0.5 1.0 0.0 0.0; 0.01 0.97 0.75 0.93 0.0 0.0])
        end
        if VERSION >= v"1.7.0"
            @test dist == [0 2 6; 2 0 5; 6 5 0] 
            @test timeWindows ==  [0 10; 4 8; 10 15]
            @test pos == [6.293451231426089 7.031298490032015; 4.503389405961936 6.733461456394963; 4.774071434328178 1.6589443479313404]
            
            sr = SeaPearl.TsptwStateRepresentation(model)

            @test sr.dist == [0.0 0.3333333333333333 1.0; 0.3333333333333333 0.0 0.8333333333333334; 1.0 0.8333333333333334 0.0]
            @test trunc.(sr.timeWindows; digits=2) == [0.0 0.66; 0.26 0.53; 0.66 1.0]
            @test trunc.(sr.pos; digits=2) == [0.62 0.7; 0.45 0.67; 0.47 0.16] 
            @test trunc.(sr.nodeFeatures; digits=2) == transpose(Float32[0.62 0.7 0.0 0.66 0.0 0.0;0.45 0.67 0.26 0.53 0.0 0.0;0.47 0.16 0.66 1.0 0.0 0.0])
        end
    end
end
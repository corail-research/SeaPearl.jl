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

        dist, time_windows, pos = model.adhocInfo

        if VERSION >= v"1.5.0"
            @test dist ==  [0 8 10; 
                            8 0 4; 
                            10 4 0]
            @test time_windows == [0 10; 8 14; 13 21]
            @test pos == [5.331830160438614 1.7293302893695128; 4.540291355871425 9.589258763297348; 0.17686826714964354 9.735659798036858]
            
            sr = SeaPearl.TsptwStateRepresentation(model)

            @test sr.dist == [  0.0 0.8 1.0
                                0.8 0.0 0.4
                                1.0 0.4 0.0]
            @test trunc.(sr.time_windows; digits=2) == [0.0  0.47
                                                        0.38 0.66
                                                        0.61 1.0]
            @test trunc.(sr.pos; digits=2) == [ 0.53 0.17
                                                0.45 0.95
                                                0.01 0.97]

            @test trunc.(sr.features; digits=2) == Float32[0.53 0.17 0.0 0.47 0.0 0.0; 0.45 0.95 0.38 0.66 0.0 0.0; 0.01 0.97 0.61 1.0 0.0 0.0]
        end
    end

    @testset "to_arraybuffer()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n_city = 3
        grid_size = 10
        max_tw_gap = 3
        max_tw = 8

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        SeaPearl.fill_with_generator!(model, generator; seed=42)

        dist, time_windows, pos = model.adhocInfo

        if VERSION >= v"1.5.0"
            @test dist ==  [0 8 10; 
                            8 0 4; 
                            10 4 0]
            @test time_windows == [0 10; 8 14; 13 21]
            @test pos == [5.331830160438614 1.7293302893695128; 4.540291355871425 9.589258763297348; 0.17686826714964354 9.735659798036858]
            
            sr = SeaPearl.TsptwStateRepresentation(model)

            @test trunc.(SeaPearl.to_arraybuffer(sr); digits=2) == Float32[ 0.0 0.8 1.0 0.53 0.17 0.0  0.47 0.0 0.0 0.0 0.0; 
                                                                            0.8 0.0 0.4 0.45 0.95 0.38 0.66 0.0 0.0 0.0 0.0; 
                                                                            1.0 0.4 0.0 0.01 0.97 0.61 1.0  0.0 0.0 0.0 0.0]

            SeaPearl.assign!(model.variables["v_2"], 2)
            SeaPearl.remove!(model.variables["a_2"].domain, 2)
            SeaPearl.remove!(model.variables["a_2"].domain, 1)
            SeaPearl.update_representation!(sr, model, model.variables["a_2"])
            @test trunc.(SeaPearl.to_arraybuffer(sr); digits=2) == Float32[ 0.0 0.8 1.0 0.53 0.17 0.0  0.47 1.0 0.0 0.0 0.0; 
                                                                            0.8 0.0 0.4 0.45 0.95 0.38 0.66 1.0 1.0 0.0 1.0; 
                                                                            1.0 0.4 0.0 0.01 0.97 0.61 1.0  0.0 0.0 1.0 0.0]
        end
    end
end
in_channel_v = 6
out_channel_v = 30
in_channel_e = 1
out_channel_e = 4
N = 4
T = Float32
adj = T[0. 1. 0. 1.;
        1. 0. 1. 0.;
        0. 1. 0. 1.;
        1. 0. 1. 0.]

adj_single_vertex =   T[0. 0. 0. 1.;
                        0. 0. 0. 0.;
                        0. 0. 0. 1.;
                        1. 0. 1. 0.]

@testset "EdgeFtLayer" begin

    @testset "Constructor" begin
        ft_layer = SeaPearl.EdgeFtLayer(in_channel_v=>out_channel_v, in_channel_e=>out_channel_e)
        

        @test size(ft_layer.W_a) == (out_channel_v, 2 * in_channel_v + in_channel_e)
        @test size(ft_layer.W_T) == (out_channel_v, 2 * in_channel_v + in_channel_e)
        @test size(ft_layer.b_T) == (out_channel_v,)
        @test size(ft_layer.W_e) == (out_channel_e, in_channel_v)
        @test size(ft_layer.W_ee) == (out_channel_e, in_channel_e)
    end

    @testset "EdgeFtLayer(fg)" begin
        ft_layer = SeaPearl.EdgeFtLayer(in_channel_v=>out_channel_v, in_channel_e=>out_channel_e)
        
        nf = rand(Float32, in_channel_v, N)
        ef = rand(Float32, in_channel_e, N, N)
        fg = SeaPearl.FeaturedGraph(adj; nf=nf, ef=ef)

        fg_ = ft_layer(fg)

        @test size(SeaPearl.node_feature(fg_)) == (out_channel_v, N)
        @test size(SeaPearl.edge_feature(fg_)) == (out_channel_e, N, N)

        g = Zygote.gradient(x -> sum(SeaPearl.node_feature(ft_layer(x))), fg)[1]
        @test size(g.nf) == size(nf)

        ft_layer2 = SeaPearl.EdgeFtLayer(out_channel_v=>10, out_channel_e=>4)
        fg2_ = ft_layer2(fg_)

        @test size(SeaPearl.node_feature(fg2_)) == (10, N)
        @test size(SeaPearl.edge_feature(fg2_)) == (4, N, N)
    end

    @testset "initialisation seed" begin
        ft_layer1 = SeaPearl.EdgeFtLayer(in_channel_v=>out_channel_v, in_channel_e=>out_channel_e; init = Flux.glorot_uniform(MersenneTwister(42)))
        ft_layer2 = SeaPearl.EdgeFtLayer(in_channel_v=>out_channel_v, in_channel_e=>out_channel_e; init = Flux.glorot_uniform(MersenneTwister(42)))
        ft_layer3 = SeaPearl.EdgeFtLayer(in_channel_v=>out_channel_v, in_channel_e=>out_channel_e; init = Flux.glorot_uniform(MersenneTwister(43)))

        @test ft_layer1.W_a == ft_layer2.W_a 
        @test ft_layer1.W_T == ft_layer2.W_T 
        @test ft_layer1.b_T == ft_layer2.b_T 
        @test ft_layer1.W_e == ft_layer2.W_e 
        @test ft_layer1.W_ee == ft_layer2.W_ee 

        @test ft_layer1.W_a != ft_layer3.W_a 
        @test ft_layer1.W_T != ft_layer3.W_T 
        @test ft_layer1.b_T != ft_layer3.b_T 
        @test ft_layer1.W_e != ft_layer3.W_e 
        @test ft_layer1.W_ee != ft_layer3.W_ee 
    end
end
using Zygote

in_channel_v = 3
out_channel_v = 5
in_channel_e = 4
out_channel_e = 2
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
        ft_layer = SeaPearl.EdgeFtLayer(;v_dim = in_channel_v=>out_channel_v, e_dim = in_channel_e=>out_channel_e)
        

        @test size(ft_layer.W_a) == (out_channel_v, 2 * in_channel_v + in_channel_e)
        @test size(ft_layer.W_T) == (out_channel_v, 2 * in_channel_v + in_channel_e)
        @test size(ft_layer.b_T) == (out_channel_v,)
        @test size(ft_layer.W_e) == (out_channel_e, in_channel_v)
        @test size(ft_layer.W_ee) == (out_channel_e, in_channel_e)
        @test isa(ft_layer.prelu_α, T)
    end

    @testset "EdgeFtLayer(fg)" begin
        ft_layer = SeaPearl.EdgeFtLayer(;v_dim = in_channel_v=>out_channel_v, e_dim = in_channel_e=>out_channel_e)
        
        nf = rand(Float32, in_channel_v, N)
        ef = rand(Float32, in_channel_e, 4)
        fg = GraphSignals.FeaturedGraph(adj; nf=nf, ef=ef)

        fg_ = ft_layer(fg)

        @test size(GraphSignals.node_feature(fg_)) == (out_channel_v, N)
        @test size(GraphSignals.edge_feature(fg_)) == (out_channel_e, 8)

        g = Zygote.gradient(x -> sum(node_feature(ft_layer(x))), fg)[1]
        @test size(g[].nf) == size(nf)
    end

    @testset "message()" begin
        ft_layer = SeaPearl.EdgeFtLayer(;v_dim = in_channel_v=>out_channel_v, e_dim = in_channel_e=>out_channel_e)
        
        nf = rand(Float32, in_channel_v, N)
        ef = rand(Float32, in_channel_e, 8)
        message_vec = GeometricFlux.message(ft_layer, nf[:, 1], nf[:, 2], ef[:, 1])

        @test size(message_vec) == (out_channel_v*2 + out_channel_e,)
    end

    @testset "apply_batch_message()" begin
        ft_layer = SeaPearl.EdgeFtLayer(;v_dim = in_channel_v=>out_channel_v, e_dim = in_channel_e=>out_channel_e)
        nf = rand(Float32, in_channel_v, N)
        ef = rand(Float32, in_channel_e, 8)
        fg = GraphSignals.FeaturedGraph(adj; nf=nf, ef=ef)

        adj_list = GeometricFlux.adjacency_list(fg)

        batch_message = GeometricFlux.apply_batch_message(ft_layer, 2, adj_list[2], GeometricFlux.edge_index_table(adj_list), ef, nf)

        @test size(batch_message) == (out_channel_v + out_channel_e, 2)
    end

    @testset "update_batch_edge()" begin
        ft_layer = SeaPearl.EdgeFtLayer(;v_dim = in_channel_v=>out_channel_v, e_dim = in_channel_e=>out_channel_e)
        nf = rand(Float32, in_channel_v, N)
        ef = rand(Float32, in_channel_e, 8)
        fg = GraphSignals.FeaturedGraph(adj; nf=nf, ef=ef)

        adj_list = GeometricFlux.adjacency_list(fg)

        every_messages = GeometricFlux.update_batch_edge(ft_layer, adj_list, ef, nf)

        @test size(every_messages) == (out_channel_v + out_channel_e, 8)
    end
end
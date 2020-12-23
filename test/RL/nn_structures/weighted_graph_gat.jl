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
        

        @test size(ft_layer.W_a) == (2 * in_channel_v + in_channel_e, out_channel_v)
        @test size(ft_layer.W_T) == (2 * in_channel_v + in_channel_e, out_channel_v)
        @test size(ft_layer.b_T) == (out_channel_v,)
        @test size(ft_layer.W_e) == (in_channel_v, out_channel_e)
        @test size(ft_layer.W_ee) == (in_channel_e, out_channel_e)
        @test isa(ft_layer.prelu_α, T)
    end
end
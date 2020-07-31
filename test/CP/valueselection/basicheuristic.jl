@testset "basicheuristic.jl" begin
    @testset "LexicographicOrder" begin 
        valueselection = SeaPearl.LexicographicOrder()
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        @test SeaPearl.selectValue(valueselection, x) == 2
    end
end
@testset "basicheuristic.jl" begin
    
    @testset "BasicHeuristic default function" begin 
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        heuristic = SeaPearl.BasicHeuristic()
        @test heuristic.selectValue(x) == 2
    end

    @testset "lexicographicValueOrdering" begin 
        valueselection = SeaPearl.lexicographicValueOrdering
        my_heuristic(x::SeaPearl.IntVar) = minimum(x.domain)
        new_valueselection = SeaPearl.BasicHeuristic(my_heuristic)
        @test new_valueselection.selectValue == my_heuristic

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        @test valueselection.selectValue(x) == 2
    end

end
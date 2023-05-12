@testset "basicheuristic.jl" begin
    
    @testset "BasicHeuristic default function" begin 
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        heuristic = SeaPearl.BasicHeuristic()
        @test heuristic.selectValue(x) == 6
    end

    @testset "BasicHeuristic" begin 
        valueselection = SeaPearl.BasicHeuristic()
        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        new_valueselection = SeaPearl.BasicHeuristic(my_heuristic)

        @test new_valueselection.selectValue == my_heuristic

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 6, "x", trailer)

        @test valueselection.selectValue(x) == 6
        @test new_valueselection.selectValue(x) == 2
    end

    include("random.jl")
end


@testset "impactheuristic.jl" begin

    trailer = SeaPearl.Trailer()
    model = SeaPearl.CPModel(trailer)
    valueselection = SeaPearl.ImpactHeuristic()

    x = SeaPearl.IntVar(2, 6, "x", trailer)
    y = SeaPearl.IntVar(2, 5, "y", trailer)
    SeaPearl.addVariable!(model, x)
    SeaPearl.addVariable!(model, y)
end
@testset "basicheuristic.jl" begin
    
    @testset "BasicHeuristic default function" begin 
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 6, "x", trailer)
        heuristic = CPRL.BasicHeuristic()
        @test heuristic.selectValue(x) == 6
    end

    @testset "BasicHeuristic" begin 
        valueselection = CPRL.BasicHeuristic()
        my_heuristic(x::CPRL.IntVar) = minimum(x.domain)
        new_valueselection = CPRL.BasicHeuristic(my_heuristic)

        @test new_valueselection.selectValue == my_heuristic

        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 6, "x", trailer)

        @test valueselection.selectValue(x) == 6
        @test new_valueselection.selectValue(x) == 2
    end

end
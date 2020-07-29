using Random

@testset "random.jl VariableSelection" begin
    @testset "RandomVariableSelection{TakeObjective=true}" begin
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x)
        SeaPearl.addVariable!(cpmodel, y)
        cpmodel.objective = y

        rng = MersenneTwister(10)

        variableselection = SeaPearl.RandomVariableSelection{true}()

        @test variableselection(cpmodel; rng=rng) == y
        @test variableselection(cpmodel; rng=rng) == x
        @test variableselection(cpmodel; rng=rng) == y
    end
    @testset "RandomVariableSelection{TakeObjective=false}" begin
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x)
        SeaPearl.addVariable!(cpmodel, y)
        cpmodel.objective = y

        rng = MersenneTwister(10)

        variableselection = SeaPearl.RandomVariableSelection{false}()

        @test variableselection(cpmodel; rng=rng) == x
        @test variableselection(cpmodel; rng=rng) == x
        @test variableselection(cpmodel; rng=rng) == x
    end
end
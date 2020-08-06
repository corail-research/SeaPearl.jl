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

        # With branchable variables
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x)
        SeaPearl.addVariable!(cpmodel, y; branchable=false)
        cpmodel.objective = y

        rng = MersenneTwister(10)

        variableselection = SeaPearl.RandomVariableSelection{true}()

        @test variableselection(cpmodel; rng=rng) == x
        @test variableselection(cpmodel; rng=rng) == x
        @test variableselection(cpmodel; rng=rng) == x
    end
    @testset "RandomVariableSelection{TakeObjective=false}" begin
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        z = SeaPearl.IntVar(1, 2, "z", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x; branchable=false)
        SeaPearl.addVariable!(cpmodel, y)
        SeaPearl.addVariable!(cpmodel, z)
        cpmodel.objective = y

        rng = MersenneTwister(10)

        variableselection = SeaPearl.RandomVariableSelection{false}()

        @test variableselection(cpmodel; rng=rng) == z
        @test variableselection(cpmodel; rng=rng) == z
        @test variableselection(cpmodel; rng=rng) == z
    end
end
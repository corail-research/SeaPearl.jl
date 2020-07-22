using Random

@testset "random.jl VariableSelection" begin
    @testset "RandomVariableSelection{TakeObjective=true}" begin
        trailer = CPRL.Trailer()
        cpmodel = CPRL.CPModel(trailer)
        x = CPRL.IntVar(1, 2, "x", trailer)
        y = CPRL.IntVar(1, 2, "y", trailer)

        CPRL.addVariable!(cpmodel, x)
        CPRL.addVariable!(cpmodel, y)
        cpmodel.objective = y

        rng = MersenneTwister(10)

        variableselection = CPRL.RandomVariableSelection{true}()

        @test variableselection(cpmodel; rng=rng) == y
        @test variableselection(cpmodel; rng=rng) == x
        @test variableselection(cpmodel; rng=rng) == y
    end
    @testset "RandomVariableSelection{TakeObjective=false}" begin
        trailer = CPRL.Trailer()
        cpmodel = CPRL.CPModel(trailer)
        x = CPRL.IntVar(1, 2, "x", trailer)
        y = CPRL.IntVar(1, 2, "y", trailer)

        CPRL.addVariable!(cpmodel, x)
        CPRL.addVariable!(cpmodel, y)
        cpmodel.objective = y

        rng = MersenneTwister(10)

        variableselection = CPRL.RandomVariableSelection{false}()

        @test variableselection(cpmodel; rng=rng) == x
        @test variableselection(cpmodel; rng=rng) == x
        @test variableselection(cpmodel; rng=rng) == x
    end
end
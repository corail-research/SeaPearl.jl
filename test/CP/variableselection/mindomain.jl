@testset "mindomain.jl VariableSelection" begin
    @testset "MinDomainVariableSelection{TakeObjective=true}" begin
        trailer = CPRL.Trailer()
        cpmodel = CPRL.CPModel(trailer)
        x1 = CPRL.IntVar(1, 4, "x1", trailer)
        x2 = CPRL.IntVar(1, 5, "x2", trailer)
        y = CPRL.IntVar(1, 6, "y", trailer)

        CPRL.addVariable!(cpmodel, x1)
        CPRL.addVariable!(cpmodel, x2)
        CPRL.addVariable!(cpmodel, y)
        cpmodel.objective = y


        variableselection = CPRL.MinDomainVariableSelection{true}()

        @test variableselection(cpmodel) == x1

        CPRL.removeAbove!(x2.domain, 3)
        @test variableselection(cpmodel) == x2

        CPRL.removeAbove!(y.domain, 2)
        @test variableselection(cpmodel) == y
    end
    @testset "MinDomainVariableSelection{TakeObjective=false}" begin
        trailer = CPRL.Trailer()
        cpmodel = CPRL.CPModel(trailer)
        x1 = CPRL.IntVar(1, 4, "x1", trailer)
        x2 = CPRL.IntVar(1, 5, "x2", trailer)
        y = CPRL.IntVar(1, 6, "y", trailer)

        CPRL.addVariable!(cpmodel, x1)
        CPRL.addVariable!(cpmodel, x2)
        CPRL.addVariable!(cpmodel, y)
        cpmodel.objective = y


        variableselection = CPRL.MinDomainVariableSelection{false}()

        @test variableselection(cpmodel) == x1

        CPRL.removeAbove!(x2.domain, 3)
        @test variableselection(cpmodel) == x2

        CPRL.removeAbove!(y.domain, 2)
        @test variableselection(cpmodel) == x2
    end
end
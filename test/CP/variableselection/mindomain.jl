@testset "mindomain.jl VariableSelection" begin
    @testset "MinDomainVariableSelection{TakeObjective=true}" begin
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        x1 = SeaPearl.IntVar(1, 4, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 5, "x2", trailer)
        y = SeaPearl.IntVar(1, 6, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x1)
        SeaPearl.addVariable!(cpmodel, x2)
        SeaPearl.addVariable!(cpmodel, y)
        cpmodel.objective = y


        variableselection = SeaPearl.MinDomainVariableSelection{true}()

        @test variableselection(cpmodel) == x1

        SeaPearl.removeAbove!(x2.domain, 3)
        @test variableselection(cpmodel) == x2

        SeaPearl.removeAbove!(y.domain, 2)
        @test variableselection(cpmodel) == y

        # With branchable branchable variables
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        x1 = SeaPearl.IntVar(1, 4, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 5, "x2", trailer)
        y = SeaPearl.IntVar(1, 6, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x1)
        SeaPearl.addVariable!(cpmodel, x2; branchable=false)
        SeaPearl.addVariable!(cpmodel, y)
        cpmodel.objective = y


        variableselection = SeaPearl.MinDomainVariableSelection{true}()

        @test variableselection(cpmodel) == x1

        SeaPearl.removeAbove!(x2.domain, 3)
        @test variableselection(cpmodel) == x1

        SeaPearl.removeAbove!(y.domain, 2)
        @test variableselection(cpmodel) == y
    end
    @testset "MinDomainVariableSelection{TakeObjective=false}" begin
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        x1 = SeaPearl.IntVar(1, 4, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 5, "x2", trailer)
        y = SeaPearl.IntVar(1, 6, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x1)
        SeaPearl.addVariable!(cpmodel, x2)
        SeaPearl.addVariable!(cpmodel, y)
        cpmodel.objective = y


        variableselection = SeaPearl.MinDomainVariableSelection{false}()

        @test variableselection(cpmodel) == x1

        SeaPearl.removeAbove!(x2.domain, 3)
        @test variableselection(cpmodel) == x2

        SeaPearl.removeAbove!(y.domain, 2)
        @test variableselection(cpmodel) == x2

        # With branchable variables
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        x1 = SeaPearl.IntVar(1, 4, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 5, "x2", trailer)
        y = SeaPearl.IntVar(1, 6, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x1; branchable=false)
        SeaPearl.addVariable!(cpmodel, x2)
        SeaPearl.addVariable!(cpmodel, y)
        cpmodel.objective = y


        variableselection = SeaPearl.MinDomainVariableSelection{false}()

        @test variableselection(cpmodel) == x2

        SeaPearl.removeAbove!(x2.domain, 3)
        @test variableselection(cpmodel) == x2

        SeaPearl.removeAbove!(y.domain, 2)
        @test variableselection(cpmodel) == x2
    end
end

@testset "failureBased.jl" begin
    @testset "FailureBasedVariableSelection{TakeObjective=false} " begin 
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        x1 = SeaPearl.IntVar(1, 4, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 3, "x2", trailer)
        x3 = SeaPearl.IntVar(1, 3, "x3", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x1)
        SeaPearl.addVariable!(cpmodel, x2)
        SeaPearl.addVariable!(cpmodel, x3)
        SeaPearl.addVariable!(cpmodel, y)
        SeaPearl.addObjective!(cpmodel,y)

        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(x1, x2, trailer))
        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(y, x2, trailer))

        variableselection = SeaPearl.FailureBasedVariableSelection{false}()
        @test variableselection(cpmodel) == x2

        SeaPearl.empty!(cpmodel)
        x1 = SeaPearl.IntVar(1, 3, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 3, "x2", trailer)
        x3 = SeaPearl.IntVar(1, 3, "x3", trailer)
        x4 = SeaPearl.IntVar(1, 3, "x4", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x1)
        SeaPearl.addVariable!(cpmodel, x2)
        SeaPearl.addVariable!(cpmodel, x3)
        SeaPearl.addVariable!(cpmodel, x4)
        SeaPearl.addVariable!(cpmodel, y)
        SeaPearl.addObjective!(cpmodel,y)

        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(x1, x2, trailer))
        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(x1, x3, trailer))
        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(x1, x4, trailer))

        @test variableselection(cpmodel) == x1

        SeaPearl.triggerInfeasible!(SeaPearl.NotEqual(x3, x4, trailer), cpmodel)
        SeaPearl.triggerInfeasible!(SeaPearl.NotEqual(x3, x4, trailer), cpmodel)
        SeaPearl.triggerInfeasible!(SeaPearl.NotEqual(x3, x4, trailer), cpmodel)

        @test variableselection(cpmodel) == x3
    end 


    @testset "FailureBasedVariableSelection{TakeObjective=true} " begin 
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        x1 = SeaPearl.IntVar(1, 4, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 3, "x2", trailer)
        x3 = SeaPearl.IntVar(1, 3, "x3", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x1)
        SeaPearl.addVariable!(cpmodel, x2)
        SeaPearl.addVariable!(cpmodel, x3)
        SeaPearl.addVariable!(cpmodel, y)
        SeaPearl.addObjective!(cpmodel, y)

        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(y, x2, trailer))

        variableselection = SeaPearl.FailureBasedVariableSelection{true}()
        @test variableselection(cpmodel) == y

        SeaPearl.empty!(cpmodel)
        x1 = SeaPearl.IntVar(1, 3, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 3, "x2", trailer)
        x3 = SeaPearl.IntVar(1, 3, "x3", trailer)
        x4 = SeaPearl.IntVar(1, 3, "x4", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x1)
        SeaPearl.addVariable!(cpmodel, x2)
        SeaPearl.addVariable!(cpmodel, x3)
        SeaPearl.addVariable!(cpmodel, x4)
        SeaPearl.addVariable!(cpmodel, y)
        SeaPearl.addObjective!(cpmodel,y)

        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(x1, x2, trailer))
        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(x1, x3, trailer))
        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(x1, x4, trailer))

        @test variableselection(cpmodel) == x1

        SeaPearl.triggerInfeasible!(SeaPearl.NotEqual(x3, x4, trailer), cpmodel)
        SeaPearl.triggerInfeasible!(SeaPearl.NotEqual(x3, x4, trailer), cpmodel)
        SeaPearl.triggerInfeasible!(SeaPearl.NotEqual(x3, x4, trailer), cpmodel)

        @test variableselection(cpmodel) == x3

        @test isnothing(cpmodel.statistics.objectives[1])
        @test isnothing(cpmodel.statistics.objectives[2])
        @test isnothing(cpmodel.statistics.objectives[3])


    end
end
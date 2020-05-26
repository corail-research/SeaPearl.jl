using MathOptInterface

const MOI = MathOptInterface
const MOIU = MathOptInterface.Utilities

using JuMP

@testset "MOI_wrapper.jl" begin

    @testset "Creating an optimizer" begin
        model = CPRL.Optimizer()
        @test MOI.get(model, MOI.SolverName()) == "CPRL Solver"
    end

    @testset "Giving parameters to the optimizer" begin
        model = CPRL.Optimizer()
        MOI.set(model, MOI.RawParameter("Test"), "test")
        @test model.options["Test"] == "test"
        MOI.empty!(model)
        @test MOI.is_empty(model)
        @test model.options["Test"] == "test"
    end

    @testset "Adding constrained variables" begin
        model = CPRL.Optimizer()
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        @test Set(keys(model.cpmodel.variables)) == Set(["1", "2", "3", "4"])
    end

    @testset "Adding constraints" begin
        model = CPRL.Optimizer()
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))

        # add new constraints
        MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(1)), MOI.LessThan(2))
        MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(2)), MOI.GreaterThan(2))
        MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(4)), MOI.Interval(2, 3))

        # use fixPoint 
        CPRL.fixPoint!(model.cpmodel, model.cpmodel.constraints)

        # test if it had effect on the variables' domains
        @test CPRL.maximum(model.cpmodel.variables[string(MOI.VariableIndex(1).value)].domain) == 2
        @test CPRL.minimum(model.cpmodel.variables[string(MOI.VariableIndex(2).value)].domain) == 2
        @test CPRL.minimum(model.cpmodel.variables[string(MOI.VariableIndex(4).value)].domain) == 2
        @test CPRL.maximum(model.cpmodel.variables[string(MOI.VariableIndex(4).value)].domain) == 3

        # add some new constraints again
        MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(3)), MOI.EqualTo(2))
        MOI.add_constraint(model, MOI.VectorOfVariables([MOI.VariableIndex(1), MOI.VariableIndex(3)]), CPRL.VariablesEquality(false))

        # perform another fixPoint
        CPRL.fixPoint!(model.cpmodel, model.cpmodel.constraints)

        # new bunch of test
        @test CPRL.isbound(model.cpmodel.variables[string(MOI.VariableIndex(1).value)])
        @test CPRL.minimum(model.cpmodel.variables[string(MOI.VariableIndex(3).value)].domain) == 2
        @test CPRL.maximum(model.cpmodel.variables[string(MOI.VariableIndex(3).value)].domain) == 2
    end

    ### Not working yet ###
    # @testset "JuMP interface" begin
    #     model = Model()
    #     set_optimizer(model, CPRL.Optimizer, bridge_constraints = true)
        
    #     @variable(model, 1 <= x[1:3] <= 4)
    #     @constraint(model, x[1] in CPRL.NotEqualTo(2))
    #     @constraint(model, x[1] in CPRL.NotEqualTo(3))
    #     @constraint(model, x[2] in MOI.EqualTo(4))
    #     @constraint(model, x[1:2] in CPRL.VariablesEquality(false))
    #     @constraint(model, [x[3], x[2]] in CPRL.VariablesEquality(false))
    #     @constraint(model, 2x[1] + 3x[2] in MOI.GreaterThan(2))
    # end


    # @testset "JuMP interface full" begin
    #     model = Model()
    #     set_optimizer(model, CPRL.Optimizer, bridge_constraints = true)
        
    #     @variable(model, 1 <= x[1:3] <= 4)
    #     @constraint(model, x[1] != 2)
    #     @constraint(model, x[1] != 3)
    #     @constraint(model, x[2] == 4)
    #     @constraint(model, x[1:2] in CPRL.VariablesEquality(false))
    #     @constraint(model, [x[3], x[2]] in CPRL.VariablesEquality(false))
    #     @constraint(model, 2x[1] + 3x[2] >= 2)

    #     println(model)
    # end
    
end
using MathOptInterface

const MOI = MathOptInterface
const MOIU = MathOptInterface.Utilities

using Test

using JuMP
using SeaPearl

@testset "MOI_wrapper.jl" begin

    include("optimizer_accessors.jl")
    include("homemade_bridging.jl")
    include("variables.jl")
    include("constraints.jl")
    include("jump.jl")

    # @testset "Creating an optimizer" begin
    #     model = SeaPearl.Optimizer()
    #     @test MOI.get(model, MOI.SolverName()) == "SeaPearl Solver"
    # end

    # @testset "Giving parameters to the optimizer" begin
    #     model = SeaPearl.Optimizer()
    #     MOI.set(model, MOI.RawParameter("Test"), "test")
    #     @test model.options["Test"] == "test"
    #     MOI.empty!(model)
    #     @test MOI.is_empty(model)
    #     @test model.options["Test"] == "test"
    # end

    # @testset "Adding constrained variables" begin
    #     model = SeaPearl.Optimizer()
    #     MOI.add_constrained_variable(model, MOI.Interval(1, 4))
    #     MOI.add_constrained_variable(model, MOI.Interval(1, 4))
    #     MOI.add_constrained_variable(model, MOI.Interval(1, 4))
    #     MOI.add_constrained_variable(model, MOI.Interval(1, 4))
    #     @test Set(keys(model.cpmodel.variables)) == Set(["1", "2", "3", "4"])
    # end

    # @testset "Adding constraints" begin
    #     model = SeaPearl.Optimizer()
    #     MOI.add_constrained_variable(model, MOI.Interval(1, 4))
    #     MOI.add_constrained_variable(model, MOI.Interval(1, 4))
    #     MOI.add_constrained_variable(model, MOI.Interval(1, 4))
    #     MOI.add_constrained_variable(model, MOI.Interval(1, 4))

    #     # add new constraints
    #     MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(1)), MOI.LessThan(2))
    #     MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(2)), MOI.GreaterThan(2))
    #     MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(4)), MOI.Interval(2, 3))

    #     # use fixPoint 
    #     SeaPearl.fixPoint!(model.cpmodel, model.cpmodel.constraints)

    #     # test if it had effect on the variables' domains
    #     @test SeaPearl.maximum(model.cpmodel.variables[string(MOI.VariableIndex(1).value)].domain) == 2
    #     @test SeaPearl.minimum(model.cpmodel.variables[string(MOI.VariableIndex(2).value)].domain) == 2
    #     @test SeaPearl.minimum(model.cpmodel.variables[string(MOI.VariableIndex(4).value)].domain) == 2
    #     @test SeaPearl.maximum(model.cpmodel.variables[string(MOI.VariableIndex(4).value)].domain) == 3

    #     # add some new constraints again
    #     MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(3)), MOI.EqualTo(2))
    #     MOI.add_constraint(model, MOI.VectorOfVariables([MOI.VariableIndex(1), MOI.VariableIndex(3)]), SeaPearl.VariablesEquality(false))

    #     # perform another fixPoint
    #     SeaPearl.fixPoint!(model.cpmodel, model.cpmodel.constraints)

    #     # new bunch of test
    #     @test SeaPearl.isbound(model.cpmodel.variables[string(MOI.VariableIndex(1).value)])
    #     @test SeaPearl.minimum(model.cpmodel.variables[string(MOI.VariableIndex(3).value)].domain) == 2
    #     @test SeaPearl.maximum(model.cpmodel.variables[string(MOI.VariableIndex(3).value)].domain) == 2
    # end

    ### Not working yet ###
    # @testset "JuMP interface" begin
    #     model = Model()
    #     set_optimizer(model, SeaPearl.Optimizer, bridge_constraints = true)
        
    #     @variable(model, 1 <= x[1:3] <= 4)
    #     @constraint(model, x[1] in SeaPearl.NotEqualTo(2))
    #     @constraint(model, x[1] in SeaPearl.NotEqualTo(3))
    #     @constraint(model, x[2] in MOI.EqualTo(4))
    #     @constraint(model, x[1:2] in SeaPearl.VariablesEquality(false))
    #     @constraint(model, [x[3], x[2]] in SeaPearl.VariablesEquality(false))
    #     @constraint(model, 2x[1] + 3x[2] in MOI.GreaterThan(2))
    # end


    # @testset "JuMP interface full" begin
    #     model = Model()
    #     set_optimizer(model, SeaPearl.Optimizer, bridge_constraints = true)
        
    #     @variable(model, 1 <= x[1:3] <= 4)
    #     @constraint(model, x[1] != 2)
    #     @constraint(model, x[1] != 3)
    #     @constraint(model, x[2] == 4)
    #     @constraint(model, x[1:2] in SeaPearl.VariablesEquality(false))
    #     @constraint(model, [x[3], x[2]] in SeaPearl.VariablesEquality(false))
    #     @constraint(model, 2x[1] + 3x[2] >= 2)

    #     println(model)
    # end
    
end
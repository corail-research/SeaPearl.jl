using MathOptInterface

const MOI = MathOptInterface
const MOIU = MathOptInterface.Utilities

using JuMP

"""
WIP 

- is MOI.VariableIndex necessary ?: we should maybe use VariableIndex in our code to allow
easier use of it in the MathOptInterface (https://www.juliaopt.org/MathOptInterface.jl/dev/apireference/#Index-types-1)
Should create a new type of Variables here or change IntVar's implementation. Not sure atm.
- not sure if it is compulsory to return a constraint while coding add_constrained_variable

"""

include("types.jl")
include("optimizer_accessors.jl")
include("sets.jl")
include("supports.jl")
include("variables.jl")
include("constraints.jl")
include("objective.jl")
include("utilities.jl")
include("homemade_bridging.jl")

"""
    MOI.optimize!(model::Optimizer)

Launch the solving process of the solver.
"""
function MOI.optimize!(model::Optimizer)
    fill_cpmodel!(model)


    status = SeaPearl.solve!(model.cpmodel; variableHeuristic=model.variableselection, valueSelection=model.valueselection)

    if status == :Optimal
        model.terminationStatus = MOI.OPTIMAL
    elseif status == :Infeasible
        model.terminationStatus = MOI.INFEASIBLE
    elseif status == :NodeLimitStop
        model.terminationStatus = MOI.NODE_LIMIT
    elseif status == :SolutionLimitStop
        model.terminationStatus = MOI.SOLUTION_LIMIT
    else
        model.terminationStatus == MOI.OTHER_ERROR
    end

    model.primalStatus = !isempty(model.cpmodel.statistics.solutions) ? MOI.FEASIBLE_POINT : MOI.NO_SOLUTION

    # println(model.cpmodel.constraints)
    
    solution = nothing
    if !isempty(model.cpmodel.statistics.solutions)
        solution = last(model.cpmodel.statistics.solutions)
    end
    # println(model.cpmodel.statistics.solutions)
    return status, solution
end


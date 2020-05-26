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

mutable struct VariableSelection <: MOI.AbstractOptimizerAttribute 
    heuristic::Function

    VariableSelection() = new(CPRL.selectVariable)
end

mutable struct Optimizer <: MOI.AbstractOptimizer
    cpmodel::CPModel
    variableselection::VariableSelection
    options::Dict{String, Any}
    #status::MOI.TerminationStatusCode

    function Optimizer()
        cpmodel = CPRL.CPModel(CPRL.Trailer())
        new(cpmodel, VariableSelection(), Dict{String, Any}())
    end
end

include("sets.jl")
include("supports.jl")
include("variables.jl")
include("constraints.jl")
include("objective.jl")
include("utilities.jl")

MOI.get(::Optimizer, ::MOI.SolverName) = "CPRL Solver"

"""
    MOI.is_empty(model::Optimizer)

Return a boolean saying if the model is empty or not. 
"""
function MOI.is_empty(model::Optimizer)
    return isempty(model.cpmodel.variables) && isempty(model.cpmodel.constraints)
end

"""
    MOI.empty!(model::Optimizer)

Empty a given Optimizer. 
"""
function MOI.empty!(model::Optimizer)
    # empty the cpmodel
    empty!(model.cpmodel.variables)
    empty!(model.cpmodel.constraints)
    empty!(model.cpmodel.trailer.current)
    empty!(model.cpmodel.trailer.prior)
    empty!(model.cpmodel.solutions)

    # do not empty the options atm
end

MOI.supports(::Optimizer, ::MOI.RawParameter) = true
MOI.supports(::Optimizer, ::CPRL.VariableSelection) = true

function MOI.set(model::Optimizer, p::MOI.RawParameter, value)
    model.options[p.name] = value
end

function MOI.set(model::Optimizer, ::CPRL.VariableSelection, heuristic::Function)
    model.variableselection.heuristic = heuristic
end


MOI.Utilities.supports_default_copy_to(model::Optimizer, copy_names::Bool) = !copy_names

function MOI.copy_to(dest::Optimizer, src::MOI.ModelLike; kwargs...)
    return MOI.Utilities.automatic_copy_to(dest, src; kwargs...)
end

"""
    MOI.optimize!(model::Optimizer)

Launch the solving process of the solver.
"""
function MOI.optimize!(model::Optimizer)
    status = CPRL.solve!(model.cpmodel; variableHeuristic=model.variableselection.heuristic)

    # println(model.cpmodel.constraints)
    
    solution = nothing
    solutions = model.cpmodel
    if !isempty(model.cpmodel.solutions)
        solution = last(model.cpmodel.solutions)
    end
    println(solution)
    return status, solution
end

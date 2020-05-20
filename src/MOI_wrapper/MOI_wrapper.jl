using MathOptInterface

const MOI = MathOptInterface
const MOIU = MathOptInterface.Utilities

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

    function Optimizer()
        cpmodel = CPRL.CPModel(CPRL.Trailer())
        new(cpmodel, VariableSelection(), Dict{String, Any}())
    end
end

include("sets.jl")
include("supports.jl")
include("variables.jl")
include("constraints.jl")

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


MOI.Utilities.supports_default_copy_to(::Optimizer, ::Bool) = true

function MOI.copy_to(dest::Optimizer, src::MOI.ModelLike; kwargs...)
    return MOI.Utilities.automatic_copy_to(dest, src; kwargs...)
end

"""
    MOI.optimize!(model::Optimizer)

Launch the solving process of the solver.
"""
function MOI.optimize!(model::Optimizer)

    solution = nothing

    found = CPRL.solve!(model.cpmodel; variableHeuristic=model.variableselection.heuristic)
    
    MAX = 4
    if (found)
        while found
            
            #for y in x
            #    push!(model.cpmodel.constraints, CPRL.LessOrEqualConstant(y, output.numberOfColors-1, trailer))
            #end
            
            
            MAX = MAX - 1
            for i in 1:4
                MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(i)), MOI.LessThan(MAX))
            end
            

            CPRL.restoreInitialState!(model.cpmodel.trailer)
            found = CPRL.solve!(model.cpmodel; variableHeuristic=model.variableselection.heuristic)

        end
        solution = last(model.cpmodel.solutions)
    end
    

    return solution
end

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

mutable struct Optimizer <: MOI.AbstractOptimizer
    cpmodel::CPModel
    options::Dict{String, Any}

    function Optimizer()
        cpmodel = CPRL.CPModel(CPRL.Trailer())
        new(cpmodel, Dict{String, Any}())
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

function MOI.set(model::Optimizer, p::MOI.RawParameter, value)
    model.options[p.name] = value
end

"""
function MOI.get(model::Optimizer, ::Degrees)
    return model.degrees
end
"""

"""
    MOI.optimize!(model::Optimizer)

Launch the solving process of the solver.
"""
function MOI.optimize!(model::Optimizer)

    degrees = model.options["degrees"]

    sortedPermutation = sortperm(degrees; rev=true)

    function selectVariable(model::CPRL.CPModel, sortedPermutation, degrees)
        maxDegree = 0
        toReturn = nothing
        for i in sortedPermutation
            if !CPRL.isbound(model.variables[string(i)])
                if isnothing(toReturn)
                    toReturn = model.variables[string(i)]
                    maxDegree = degrees[i]
                end
                if degrees[i] < maxDegree
                    return toReturn
                end

                if length(model.variables[string(i)].domain) < length(toReturn.domain)
                    toReturn = model.variables[string(i)]
                end
            end
        end
        return toReturn
    end

    solution = nothing

    found = CPRL.solve!(model.cpmodel; variableHeuristic=((m) -> selectVariable(m, sortedPermutation, degrees)))

    if (found)
        while found
            """
            for y in x
                push!(model.cpmodel.constraints, CPRL.LessOrEqualConstant(y, output.numberOfColors-1, trailer))
            end
            """
            CPRL.restoreInitialState!(model.cpmodel.trailer)
            found = CPRL.solve!(model.cpmodel; variableHeuristic=((m) -> selectVariable(m, sortedPermutation, degrees)))

        end
        solution = last(model.cpmodel.solutions)
    end

    return solution
end

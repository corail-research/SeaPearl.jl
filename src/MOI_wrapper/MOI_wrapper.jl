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

    function Optimizer()
        cpmodel = CPRL.CPModel(CPRL.Trailer())
        new(cpmodel)
    end
end

include("sets.jl")
include("supports.jl")
include("variables.jl")
include("constraints.jl")


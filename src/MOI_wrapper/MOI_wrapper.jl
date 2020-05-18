using MathOptInterface

const MOI = MathOptInterface

"""
WIP 

- is MOI.VariableIndex necessary ?: we should maybe use VariableIndex in our code to allow
easier use of it in the MathOptInterface (https://www.juliaopt.org/MathOptInterface.jl/dev/apireference/#Index-types-1)
Should create a new type of Variables here or change IntVar's implementation. Not sure atm.
- 

"""

mutable struct Optimizer <: MOI.AbstractOptimizer
    cpmodel::CPModel

    function Optimizer()
        cpmodel = CPRL.CPModel(CPRL.Trailer())
        new(cpmodel)
    end
end

"""
    MOI.add_variable(model::Optimizer)

Interface function which add a variable to the model (which is himself an Optimizer)
"""
function MOI.add_variable(model::Optimizer)
    """
    Tried with min = 0 and max = typemax(Int) but got an Array size error.
    Should think about the min/max initialisation. I temporarly put 2048 as max.
    """
    MAX_SIZE = 2048
    id = string(length(keys(model.cpmodel.variables)) + 1)
    newvariable = CPRL.IntVar(0, 1, id, model.cpmodel.trailer)
    CPRL.addVariable!(model.cpmodel, newvariable)
    return MOI.VariableIndex(parse(Int, id))
end

MOI.add_variables(model::Optimizer, n::Int) = [MOI.add_variable(model) for i = 1:n]

"""
    MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::MOI.EqualTo)

Interface function which add a constraint to the model (which is himself an Optimizer).
This constraints a single variable to be different than a given Integer.  
"""
function MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::MOI.EqualTo)
    # get the VariableIndex and convert it to string
    id = string(sgvar.variable)
    constant = set.value

    # create the constraint
    constraint = EqualConstant(model.cpmodel.variables[id], constant, model.cpmodel.trailer)

    # add constraint to the model
    push!(model.cpmodel.constraints, constraint)

    # return the constraint Index (asked by MathOptInterface)
    constraint_index = length(model.cpmodel.constraints) + 1
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.EqualTo}(constraint_index)
end

"""
    MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::MOI.Interval)

Interface function which add a constraint to the model (which is himself an Optimizer)
This constraints a single variable to be in a given interval.
"""
function MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::MOI.Interval)
    # get the VariableIndex and convert it to string
    id = string(sgvar.variable)
    min = set.lower
    max = set.upper

    # create the constraint: need to create the native one first (WIP)
    constraint = nothing

    # add constraint to the model
    push!(model.cpmodel.constraints, constraint)

    # return the constraint Index (asked by MathOptInterface)
    constraint_index = length(model.cpmodel.constraints) + 1
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.EqualTo}(constraint_index)
end

add_constraint() = @info "Constraint added !"


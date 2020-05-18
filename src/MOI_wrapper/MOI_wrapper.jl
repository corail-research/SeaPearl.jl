using MathOptInterface

const MOI = MathOptInterface

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

"""
    MOI.add_variable(model::Optimizer)

Interface function which add a variable to the model (which is himself an Optimizer)
"""
function MOI.add_constrained_variable(model::Optimizer, set::MOI.Interval)
    """
    Might be compulsory to create a new constraint: variable in interval, to create it 
    in this function and to throw it at the end (instead of nothing)
    """
    # create new id
    id = string(length(keys(model.cpmodel.variables)) + 1)

    # get information from the set
    min = set.lower
    max = set.upper

    newvariable = CPRL.IntVar(min, max, id, model.cpmodel.trailer)
    CPRL.addVariable!(model.cpmodel, newvariable)
    return MOI.VariableIndex(parse(Int, id)), nothing
end

"""
    MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::MOI.EqualTo)

Interface function which add a constraint to the model (which is himself an Optimizer).
This constraints a single variable to be equal to a given Integer.  
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

struct NotEqualTo <: MOI.AbstractScalarSet
    value::Int
end

"""
    MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::NotEqualTo)

Interface function which add a constraint to the model (which is himself an Optimizer)
This constraints a single variable to be equal to a given interval.
"""
function MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::NotEqualTo)
    # get the VariableIndex and convert it to string
    id = string(sgvar.variable)
    constant = set.value

    # create the constraint: need to create the native one first (WIP)
    constraint = NotEqualConstant(model.cpmodel.variables[id], constant, model.cpmodel.trailer)

    # add constraint to the model
    push!(model.cpmodel.constraints, constraint)

    # return the constraint Index (asked by MathOptInterface)
    constraint_index = length(model.cpmodel.constraints) + 1
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.NotEqualTo}(constraint_index)
end

add_constraint() = @info "Constraint added !"


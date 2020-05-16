using MathOptInterface

const MOI = MathOptInterface

"""
WIP 

- is MOI.VariableIndex necessary ?
- 

"""

mutable struct Optimizer <: MOI.AbstractOptimizer
    cpmodel::CPModel

    function Optimizer()
        cpmodel = CPRL.CPModel(CPRL.Trailer())
        new(cpmodel)
    end
end

function MOI.add_variable(model::Optimizer)
    """
    Tried with min = 0 and max = typemax(Int) but got an Array size error.
    Should think about the min/max initialisation. 
    """
    id = string(length(keys(model.cpmodel.variables)) + 1)
    newvariable = CPRL.IntVar(0, 1, id, model.cpmodel.trailer)
    CPRL.addVariable!(model.cpmodel, newvariable)
end

MOI.add_variables(model::Optimizer, n::Int) = [MOI.add_variable(model) for i = 1:n]

add_constraint() = @info "Constraint added !"


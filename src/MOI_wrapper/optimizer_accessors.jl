MOI.get(::Optimizer, ::MOI.SolverName) = "CPRL Solver"
MOI.get(model::Optimizer, ::MOI.TerminationStatus) = model.terminationStatus
MOI.get(model::Optimizer, ::MOI.PrimalStatus) = model.primalStatus

function MOI.get(optimizer::CPRL.Optimizer, ::MathOptInterface.VariablePrimal, vi::MathOptInterface.VariableIndex)
    id = vi.value
    last(optimizer.cpmodel.solutions)[string(id)]
end

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
MOI.supports(::Optimizer, ::MOI.VariablePrimal) = true

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
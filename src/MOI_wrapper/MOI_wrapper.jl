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

mutable struct MOIVariable
    name::String
    min::Union{Nothing, Int}
    max::Union{Nothing, Int}
    vi::MOI.VariableIndex
end

struct MOIConstraint{T <: Constraint}
    type::Type{T}
    args::Tuple
    ci::MOI.ConstraintIndex
end

mutable struct MOIModel
    variables::Array{MOIVariable}
    constraints::Array{MOIConstraint}
    objectiveId::Union{Nothing, Int}
    MOIModel() = new(MOIVariable[], MOIConstraint[], nothing)
end

mutable struct VariableSelection <: MOI.AbstractOptimizerAttribute 
    heuristic::Function

    VariableSelection() = new(CPRL.selectVariable)
end

mutable struct Optimizer <: MOI.AbstractOptimizer
    cpmodel::CPModel
    moimodel::MOIModel
    variableselection::VariableSelection
    options::Dict{String, Any}
    terminationStatus::MOI.TerminationStatusCode
    primalStatus::MOI.ResultStatusCode

    function Optimizer()
        cpmodel = CPRL.CPModel(CPRL.Trailer())
        new(cpmodel, MOIModel(), VariableSelection(), Dict{String, Any}(), MOI.OPTIMIZE_NOT_CALLED)
    end
end



include("sets.jl")
include("supports.jl")
include("variables.jl")
include("constraints.jl")
include("objective.jl")
include("utilities.jl")

MOI.get(::Optimizer, ::MOI.SolverName) = "CPRL Solver"
MOI.get(model::Optimizer, ::MOI.TerminationStatus) = model.terminationStatus
MOI.get(model::Optimizer, ::MOI.PrimalStatus) = model.primalStatus

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

function fill_cpmodel!(optimizer::Optimizer)
    # Adding variables
    i = 1
    for x in optimizer.moimodel.variables
        @assert !isnothing(x.min) "Every variable must have a lower bound"
        @assert !isnothing(x.max) "Every variable must have an upper bound"
        x.name = x.name*string(i)
        newvariable = CPRL.IntVar(x.min, x.max, x.name, optimizer.cpmodel.trailer)
        CPRL.addVariable!(optimizer.cpmodel, newvariable)
        i += 1
    end

    # Adding constraints
    for moiconstraint in optimizer.moimodel.constraints
        constraint = create_CPConstraint(moiconstraint, optimizer)

        # add constraint to the model
        push!(optimizer.cpmodel.constraints, constraint)
    end

    optimizer
end

"""
    MOI.optimize!(model::Optimizer)

Launch the solving process of the solver.
"""
function MOI.optimize!(model::Optimizer)
    fill_cpmodel!(model)

    println(model.cpmodel)


    status = CPRL.solve!(model.cpmodel; variableHeuristic=model.variableselection.heuristic)

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

    model.primalStatus = !isempty(model.cpmodel.solutions) ? MOI.FEASIBLE_POINT : MOI.NO_SOLUTION

    # println(model.cpmodel.constraints)
    
    solution = nothing
    solutions = model.cpmodel
    if !isempty(model.cpmodel.solutions)
        solution = last(model.cpmodel.solutions)
    end
    println(solution)
    return status, solution
end


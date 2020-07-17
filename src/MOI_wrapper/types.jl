struct AffineIndex
    value::Int
end

mutable struct MOIVariable
    cp_identifier::String
    min::Union{Nothing, Int}
    max::Union{Nothing, Int}
    vi::MOI.VariableIndex
end

struct MOIConstraint{T <: Union{MOI.AbstractSet, CPRL.Constraint}}
    type::Type{T}
    args::Tuple
    ci::MOI.ConstraintIndex
end

mutable struct MOIAffineFunction
    cp_identifier::Union{Nothing, String}
    content::MOI.ScalarAffineFunction
end

mutable struct MOIModel
    variables::Array{MOIVariable}
    constraints::Array{MOIConstraint}
    affines::Array{MOIAffineFunction}
    objective_identifier::Union{Nothing, AffineIndex, MOI.VariableIndex}
    MOIModel() = new(MOIVariable[], MOIConstraint[], MOIAffineFunction[], nothing)
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

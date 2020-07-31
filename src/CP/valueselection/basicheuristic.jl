
"""
    abstract type AbstractBasicHeuristic <: AbstractValueSelection end

A `AbstractBasicHeuristic` is any type of `AbstractValueSelection` that is not learning. It makes it possible to use 
SeaPearl.jl as a classic CP Solver. This is useful in itself as it is a fully Julia native CP Solver.
This is also useful to be able to compare the performances of the LearnedHeuristic to some handcrafted heuristics.

To create one, the user just has to create a new concrete type subtyped from `AbstractBasicHeuristic` and dispatch
`selectValue(::AbstractBasicHeuristic, ::AbstractVar)` on this new type.
"""
abstract type AbstractBasicHeuristic <: AbstractValueSelection end

selectValue(h::AbstractBasicHeuristic, ::AbstractVar) = throw(ErrorException("Value-selection heuristic $(typeof(h)) not implemented."))

"""
    struct LexicographicOrder <: AbstractBasicHeuristic end
    
Value ordering heuristic that selects the minimum value of the domain
"""
struct LexicographicOrder <: AbstractBasicHeuristic end

selectValue(::LexicographicOrder, x::AbstractVar) = minimum(x.domain)

"""
    (valueSelection::AbstractBasicHeuristic)(::LearningPhase, model, x, current_status)

Explains what an `AbstractBasicHeuristic` should do at each step of the solving. This is useful to have a unified `search!` function working with both
`AbstractBasicHeuristic` and `LearnedHeuristic`. In the case of the `AbstractBasicHeuristic`, it is only called in the `DecisionPhase` where the `selectValue` function is used
to choose the value assigned. 
"""
(valueSelection::AbstractBasicHeuristic)(::InitializingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::AbstractBasicHeuristic)(::StepPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::AbstractBasicHeuristic)(::DecisionPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = selectValue(valueSelection, x)
(valueSelection::AbstractBasicHeuristic)(::EndingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

wears_mask(valueSelection::AbstractBasicHeuristic) = true
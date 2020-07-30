
"""
    BasicHeuristic(selectValue::Function)

A BasicHeuristic is the type of ValueSelection that is not learning. It makes it possible to use 
SeaPearl.jl as a classic CP Solver. This is useful in itself as it is a fully julia native CP Solver.
This is also useful to be able to compare the performances of the LearnedHeuristic to some handcrafted heuristics.

To create one, the user just as to give it a function which map an `AbstractIntVar` to a value of its domain. 
"""
mutable struct BasicHeuristic <: ValueSelection
    selectValue::Function
end

"""
    lexicographicValueOrdering
    
Create the default `BasicHeuristic` that selects the minimum value of the domain
"""
lexicographicValueOrdering = BasicHeuristic(x -> minimum(x.domain))

"""
    BasicHeuristic()
    
Create the default `BasicHeuristic` (`lexicographicValueOrdering` by default)
"""
BasicHeuristic() = lexicographicValueOrdering

"""
    (valueSelection::BasicHeuristic)(::LearningPhase, model, x, current_status)

Explains what the basicHeurstic should do at each step of the solving. This is useful to have a unified `search!` function working with both
BasicHeuristic and LearnedHeuristic. In the case of the BasicHeuristic, it is only called in the DecisionPhase where the selectValue function is used
to choose the value assigned. 
"""
(valueSelection::BasicHeuristic)(::InitializingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::BasicHeuristic)(::StepPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::BasicHeuristic)(::DecisionPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = valueSelection.selectValue(x)
(valueSelection::BasicHeuristic)(::EndingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

wears_mask(valueSelection::BasicHeuristic) = true
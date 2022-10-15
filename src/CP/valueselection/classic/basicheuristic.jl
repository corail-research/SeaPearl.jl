
"""
    BasicHeuristic(selectValue::Function)

A BasicHeuristic is the type of ValueSelection that is not learning. It makes it possible to use 
SeaPearl.jl as a classic CP Solver. This is useful in itself as it is a fully julia native CP Solver.
This is also useful to be able to compare the performances of the LearnedHeuristic to some handcrafted heuristics.

To create one, the user simply has to give it a function which maps an `AbstractIntVar` to a value of its domain. 
"""
mutable struct BasicHeuristic <: ValueSelection
    selectValue::Function
    search_metrics::Union{Nothing, SearchMetrics} # question: SearchMetrics ??

end

"""
    BasicHeuristic()
    
Create the default `BasicHeuristic`. By default, it selects the maximum value of the domain for the given variable, but will be overridden by the heuristic function given to it.
"""
BasicHeuristic() = BasicHeuristic((x; cpmodel=nothing) -> maximum(x.domain), nothing)
BasicHeuristic(selectValue::Function) = BasicHeuristic(selectValue, nothing)
"""
    (valueSelection::BasicHeuristic)(::LearningPhase, model, x, current_status)

Explains what the BasicHeurstic should do at each step of the solving. This is useful to have a unified `search!` function working with both
BasicHeuristic and LearnedHeuristic. In the case of the BasicHeuristic, it is only called in the DecisionPhase where the selectValue function is used
to choose the value assigned. 
"""
(valueSelection::BasicHeuristic)(::Type{InitializingPhase}, model::Union{Nothing, CPModel}=nothing) = (valueSelectionsearch_metrics = SearchMetrics(model))  # question: tout ce bloc-> dispatch selon le type d'input?
(valueSelection::BasicHeuristic)(::Type{StepPhase}, model::Union{Nothing, CPModel}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
function (valueSelection::BasicHeuristic)(::Type{DecisionPhase}, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing) # question: du mal avec les fonctions anonymes
    model.statistics.lastVar = x
    return valueSelection.selectValue(x; cpmodel=model)
end
(valueSelection::BasicHeuristic)(::Type{EndingPhase}, model::Union{Nothing, CPModel}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

wears_mask(valueSelection::BasicHeuristic) = true # question: ??

include("random.jl")
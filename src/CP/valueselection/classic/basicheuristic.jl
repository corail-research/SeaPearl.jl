
"""
    BasicHeuristic(selectValue::Function)

A BasicHeuristic is the type of ValueSelection that is not learning. It makes it possible to use 
SeaPearl.jl as a classic CP Solver. This is useful in itself as it is a fully julia native CP Solver.
This is also useful to be able to compare the performances of the LearnedHeuristic to some handcrafted heuristics.

To create one, the user just as to give it a function which map an `AbstractIntVar` to a value of its domain. 
"""
mutable struct BasicHeuristic <: ValueSelection
    selectValue::Function
    search_metrics::Union{Nothing, SearchMetrics}

end

"""
    BasicHeuristic()
    
Create the default `BasicHeuristic` that selects the maximum value of the domain
"""
BasicHeuristic() = BasicHeuristic((x; cpmodel=nothing) -> maximum(x.domain), nothing)
BasicHeuristic(selectValue::Function) = BasicHeuristic(selectValue, nothing)
"""
    (valueSelection::BasicHeuristic)(::LearningPhase, model, x, current_status)

Explains what the basicHeurstic should do at each step of the solving. This is useful to have a unified `search!` function working with both
BasicHeuristic and LearnedHeuristic. In the case of the BasicHeuristic, it is only called in the DecisionPhase where the selectValue function is used
to choose the value assigned. 
"""
(valueSelection::BasicHeuristic)(::Type{InitializingPhase}, model::Union{Nothing, CPModel}=nothing) = (valueSelection.search_metrics = SearchMetrics(model))
(valueSelection::BasicHeuristic)(::Type{StepPhase}, model::Union{Nothing, CPModel}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
function (valueSelection::BasicHeuristic)(::Type{DecisionPhase}, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing) 
    model.statistics.lastVar = x
    model.statistics.lastVal = valueSelection.selectValue(x; cpmodel=model)
    
    return model.statistics.lastVal
end
(valueSelection::BasicHeuristic)(::Type{EndingPhase}, model::Union{Nothing, CPModel}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

wears_mask(valueSelection::BasicHeuristic) = true
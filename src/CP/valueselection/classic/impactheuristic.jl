"""
    ImpactHeuristic <: ValueSelection
Impact-Based heuristic: 
"""
mutable struct ImpactHeuristic <: ValueSelection
    search_metrics::Union{Nothing, SearchMetrics}
end

"""
    ImpactHeuristic()
Create the default `ImpactHeuristic` :
"""

ImpactHeuristic() = ImpactHeuristic(nothing)
"""
    (valueSelection::ImpactHeuristic)(::LearningPhase, model, x, current_status)

Explains what the ImpactHeuristic should do at each step of the solving. This is useful to have a unified `search!` function working with both ImpactHeuristic and LearnedHeuristic. 
In the case of the ImpactHeuristic, it is only called in the DecisionPhase where the selectValue function is used to choose the value assigned. 
"""

(valueSelection::ImpactHeuristic)(::Type{InitializingPhase}, model::Union{Nothing, CPModel}=nothing) = (valueSelection.search_metrics = SearchMetrics(model))
(valueSelection::ImpactHeuristic)(::Type{StepPhase}, model::Union{Nothing, CPModel}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

function (valueSelection::ImpactHeuristic)(::Type{DecisionPhase}, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing) 
    model.statistics.lastVar = x
    d = Dict()
    for v in x.domain
        d[(x,v)] = !isnothing(get(model.impact_var_val, (x,v), nothing)) ? model.impact_var_val[(x,v)] : 0.1
    end
    model.statistics.lastVal = collect(keys(d))[argmax(collect(values(d)))][2]
    return model.statistics.lastVal
end

(valueSelection::ImpactHeuristic)(::Type{EndingPhase}, model::Union{Nothing, CPModel}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

wears_mask(valueSelection::ImpactHeuristic) = true

# include("random.jl")
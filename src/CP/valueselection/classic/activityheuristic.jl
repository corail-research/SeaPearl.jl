
"""
    ActivityHeuristic <: ValueSelection
 
"""
mutable struct ActivityHeuristic <: ValueSelection
    search_metrics::Union{Nothing, SearchMetrics}
end

"""
    ActivityHeuristic()
    
Create the default `ActivityHeuristic` :
"""
ActivityHeuristic() = ActivityHeuristic(nothing)
"""
    (valueSelection::ActivityHeuristic)(::LearningPhase, model, x, current_status)

Explains what the ActivityHeuristic should do at each step of the solving. This is useful to have a unified `search!` function working with both ActivityHeuristic and LearnedHeuristic. In the case of the ActivityHeuristic, it is only called in the DecisionPhase where the selectValue function is used to choose the value assigned. 
"""
(valueSelection::ActivityHeuristic)(::Type{InitializingPhase}, model::Union{Nothing, CPModel}=nothing) = (valueSelection.search_metrics = SearchMetrics(model))

(valueSelection::ActivityHeuristic)(::Type{StepPhase}, model::Union{Nothing, CPModel}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

function (valueSelection::ActivityHeuristic)(::Type{DecisionPhase}, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing) 
    model.statistics.lastVar = x
    d = Dict()
    for v in x.domain
        d[(x,v)] = !isnothing(get(model.activity_var_val, (x,v), nothing)) ? model.activity_var_val[(x,v)] : 0.1*length(model.branchable_variables)
    end

    model.statistics.lastVal = collect(keys(d))[argmin(collect(values(d)))][2] #Caution : here we need to select the valu with the least activity

    return model.statistics.lastVal
end

(valueSelection::ActivityHeuristic)(::Type{EndingPhase}, model::Union{Nothing, CPModel}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

wears_mask(valueSelection::ActivityHeuristic) = true

include("random.jl")
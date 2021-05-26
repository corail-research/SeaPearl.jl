


"""
        AbstractMetrics

AbstractMetrics is a data structure that allows the user the stock relevant informations 
of consecutive search along learning (either on different instances or on the same one).  

SeaPearl allows the user to define his own CustomMetrics as long as the user defines the function
(::CustomMetrics)(model::CPmodel,dt::Float64) which is the generic call to AbstractMetrics made
just after the search.

The user can add new features on its CustomMetrics such as advanced plotting. 
"""
abstract type AbstractMetrics end


"""
        AbstractTakeObjective

The structure TakeObjective and DontTakeObjective are used as parametric type for the 
basicmetrics{OBJ<:AbstractTakeObjective, H<:ValueSelection} definition. It indicates if the 
CP problem (knapsack, graphcoloring, tsptw ...) that the metrics is attached to deals with 
an objective function or not. 

If yes, after a search on a given problem instance, the metrics will also retrieve the solution scores along the search. 
"""
abstract type AbstractTakeObjective end 
struct TakeObjective<:AbstractTakeObjective end
struct DontTakeObjective<:AbstractTakeObjective end


include("basicmetrics.jl")

#TODO implement this function to compare several heuristic results
"""function plot_diff_metrics(...)
    
end
"""
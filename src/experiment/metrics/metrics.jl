abstract type AbstractMetrics end

abstract type AbstractTakeObjective end 

struct TakeObjective<:AbstractTakeObjective end
struct DontTakeObjective<:AbstractTakeObjective end



include("basicmetrics.jl")

#TODO implement this function
"""function plot_diff_metrics(...)
    
end
"""
abstract type AbstractEvaluator end

mutable struct SameInstancesEvaluator <: AbstractEvaluator
    instances::Union{Array{CPModel}, Nothing}
    metrics::Union{Matrix{<:AbstractMetrics}, Nothing} 
    evalFreq::Int64
    nbInstances::Int64
    nbHeuristics::Union{Int64, Nothing}
end

function SameInstancesEvaluator(valueSelectionArray::Array{H, 1}, generator::AbstractModelGenerator; seed=nothing, evalFreq::Int64 = 50, nbInstances::Int64 = 10, evalTimeOut::Union{Nothing,Int64} = nothing) where H<: ValueSelection
    instances = Array{CPModel}(undef, nbInstances)
    metrics = Matrix{AbstractMetrics}(undef,nbInstances, size(valueSelectionArray,1)) 
    
    for i in 1:nbInstances
        instances[i] = CPModel()
        fill_with_generator!(instances[i], generator; seed=seed)
        instances[i].limit.searchingTime = evalTimeOut
        for (j, value) in enumerate(valueSelectionArray)
            metrics[i,j]=BasicMetrics(instances[i],value;meanOver=1)   #no slidding mean on evaluation because the instance remains the same
        end 
    end    
    SameInstancesEvaluator(instances, metrics, max(1,evalFreq), nbInstances, size(valueSelectionArray,1))
end

function evaluate(eval::SameInstancesEvaluator, variableHeuristic::AbstractVariableSelection, strategy::S; verbose::Bool=true) where{S<:SearchStrategy}
    for j in 1:eval.nbHeuristics
        heuristic = eval.metrics[1,j].heuristic
        initsize = isa(heuristic, LearnedHeuristic) ? length(heuristic.agent.trajectory) : nothing

        testmode!(heuristic, true)
        for i in 1:eval.nbInstances
            model = eval.instances[i]
            reset_model!(model)

            dt = @elapsed search!(model, strategy, variableHeuristic, heuristic)
            eval.metrics[i,j](model,dt)

            verbose && println(typeof(heuristic), " evaluated with: ", model.statistics.numberOfNodes, " nodes, taken ", dt, "s, number of solutions found : ", model.statistics.numberOfSolutions)
        end 
        testmode!(heuristic, false)
        if !isnothing(initsize)
            @assert length(heuristic.agent.trajectory) == initsize "You have leaks in your evaluation pipeline!"
        end
    end
end




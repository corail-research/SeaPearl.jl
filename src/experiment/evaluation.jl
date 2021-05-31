abstract type AbstractEvaluator end

mutable struct SameInstancesEvaluator <: AbstractEvaluator
    instances::Union{Array{CPModel}, Nothing}
    metrics::Union{Matrix{<:AbstractMetrics}, Nothing} 
    evalFreq::Int64
    nbInstances::Int64
    nbHeuristics::Union{Int64, Nothing}
end

function SameInstancesEvaluator(valueSelectionArray::Array{H, 1}, generator::AbstractModelGenerator; seed=nothing, evalFreq = 50, nbInstances = 10) where H<: ValueSelection
    instances = Array{CPModel}(undef, nbInstances)
    metrics = Matrix{AbstractMetrics}(undef,nbInstances, size(valueSelectionArray,1)) 
    
    for i in 1:nbInstances
        instances[i] = CPModel()
        fill_with_generator!(instances[i], generator; seed=seed)
        for (j, value) in enumerate(valueSelectionArray)
            metrics[i,j]=BasicMetrics(instances[i],value;meanOver=1)   #no slidding mean on evaluation because the instance remains the same
        end 
    end    
    SameInstancesEvaluator(instances, metrics, evalFreq, nbInstances, size(valueSelectionArray,1))
end

function evaluate(eval::SameInstancesEvaluator, variableHeuristic::AbstractVariableSelection, strategy::Type{<:SearchStrategy})

    for j in 1:eval.nbHeuristics
        testmode!(eval.metrics[1,j].heuristic, true)
        for i in 1:eval.nbInstances
            model = eval.instances[i]
            reset_model!(model)

            dt = @elapsed search!(model, strategy, variableHeuristic, eval.metrics[1,j].heuristic)
            eval.metrics[i,j](model,dt)

            println(typeof(eval.metrics[1,j].heuristic), " evaluated with: ", model.statistics.numberOfNodes, " nodes, taken ", dt, "s")
        end 
        testmode!(eval.metrics[1,j].heuristic, false)
    end
end




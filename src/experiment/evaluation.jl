abstract type AbstractEvaluator end

mutable struct SameInstancesEvaluator <: AbstractEvaluator
    instances::Union{Array{CPModel}, Nothing}
    metrics::Union{Array{Any,2}, Nothing} 
    eval_freq::Int64
    nb_instances::Int64
    nb_heuristic::Union{Int64, Nothing}
end

function SameInstancesEvaluator(valueSelectionArray::Array{H, 1}, generator::AbstractModelGenerator; seed=nothing, eval_freq = 50, nb_instances = 10) where H<: ValueSelection
    instances = Array{CPModel}(undef, nb_instances)
    metrics = Array{Any,2}(undef,nb_instances, size(valueSelectionArray,1)) 
    
    for i in 1:nb_instances
        instances[i] = CPModel()
        fill_with_generator!(instances[i], generator; seed=seed)
        for (j, value) in enumerate(valueSelectionArray)
            metrics[i,j]=basicmetrics(instances[i],value;meanOver=1)   #no slidding mean on evaluation because the instance remains the same
        end 
    end    
    SameInstancesEvaluator(instances, metrics, eval_freq, nb_instances, size(valueSelectionArray,1))
end

function evaluate(eval::SameInstancesEvaluator, variableHeuristic::AbstractVariableSelection, strategy::Type{<:SearchStrategy})

    for j in 1:eval.nb_heuristic
        testmode!(eval.metrics[1,j].heuristic, true)
        for i in 1:eval.nb_instances
            model = eval.instances[i]
            reset_model!(model)

            dt = @elapsed search!(model, strategy, variableHeuristic, eval.metrics[1,j].heuristic)
            eval.metrics[i,j](model,dt)

            println(typeof(eval.metrics[1,j].heuristic), " evaluated with: ", model.statistics.numberOfNodes, " nodes, taken ", dt, "s")
        end 
        testmode!(eval.metrics[1,j].heuristic, false)
    end
end




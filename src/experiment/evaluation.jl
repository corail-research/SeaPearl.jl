abstract type AbstractEvaluator end

mutable struct SameInstancesEvaluator <: AbstractEvaluator
    instances::Union{Array{CPModel}, Nothing}
    eval_freq::Int
    nb_instances::Int
end

function SameInstancesEvaluator(; eval_freq = 50, nb_instances = 50)
    SameInstancesEvaluator(nothing, eval_freq, nb_instances)
end

function init_evaluator!(eval::SameInstancesEvaluator, generator::AbstractModelGenerator; rng=nothing)
    instances = Array{CPModel}(undef, eval.nb_instances)
    for i in 1:eval.nb_instances
        instances[i] = CPModel()
        fill_with_generator!(instances[i], generator; rng=rng)
    end
    eval.instances = instances
end

function evaluate(eval::SameInstancesEvaluator, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, strategy::Type{<:SearchStrategy})
    testmode!(valueSelection, true)
    n = length(eval.instances)
    dt = 0.
    n_nodes = 0.
    for model in eval.instances
        reset_model!(model)

        dt += @elapsed search!(model, strategy, variableHeuristic, valueSelection)
        n_nodes += model.statistics.numberOfNodes
    end
    testmode!(valueSelection, false)
    return n_nodes/n, dt/n
    # return 0., 0.
end




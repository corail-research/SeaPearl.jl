abstract type AbstractEvaluator end

mutable struct SameInstancesEvaluator <: AbstractEvaluator
    instances::Union{Array{CPModel}, Nothing}
    eval_freq::Int
    nb_instances::Int
end

function SameInstancesEvaluator(; eval_freq = 50, nb_instances = 50)
    SameInstancesEvaluator(nothing, eval_freq, nb_instances)
end

function init_evaluator!(eval::SameInstancesEvaluator, generator::AbstractModelGenerator; seed=nothing)
    instances = Array{CPModel}(undef, eval.nb_instances)
    for i in 1:eval.nb_instances
        instances[i] = CPModel()
        fill_with_generator!(instances[i], generator; seed=seed)
    end
    eval.instances = instances
end

function evaluate(eval::SameInstancesEvaluator, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, strategy::Type{<:SearchStrategy})
    testmode!(valueSelection, true)
    n = length(eval.instances)
    dt = zeros(Float64, eval.nb_instances)
    n_nodes = zeros(Int64, eval.nb_instances)

    for i in 1:eval.nb_instances
        model = eval.instances[i]
        reset_model!(model)

        cur_dt = @elapsed search!(model, strategy, variableHeuristic, valueSelection)

        dt[i] = cur_dt
        n_nodes[i] = model.statistics.numberOfNodes
        println(typeof(valueSelection), " evaluated with: ", model.statistics.numberOfNodes, " nodes, taken ", cur_dt, "s")

    end
    testmode!(valueSelection, false)
    return n_nodes, dt
end




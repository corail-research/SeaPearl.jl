abstract type AbstractEvaluator end

mutable struct SameInstancesEvaluator <: AbstractEvaluator
    instances::Array{CPModel}
end

function SameInstancesEvaluator(generator::AbstractModelGenerator, number_of_instances)
    instances = Array{CPModel}(undef, number_of_instances)
    for i in 1:number_of_instances
        instances[i] = CPModel()
        fill_with_generator!(instances[i], generator)
    end
    SameInstancesEvaluator(instances)
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




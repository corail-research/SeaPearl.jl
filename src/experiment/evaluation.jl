"""
    abstract type AbstractEvaluator end

Used to define any Evaluator. An Evaluator is an object that will be called during training to evaluate the performance of multiple heuristics on CP instances.
"""
abstract type AbstractEvaluator end

"""
    mutable struct SameInstancesEvaluator <: AbstractEvaluator
        instances::Union{Array{CPModel}, Nothing}               -> evaluation instances
        metrics::Union{Matrix{<:AbstractMetrics}, Nothing}      -> 2D Matrix containing AbstractMetrics for each evaluation instance on the y-axis, for each heuristic on the x-axis. 
        evalFreq::Int64                                         -> frequency at which heuristics need to be evaluated in terms of training episode.
        nbInstances::Int64                                      -> number of evaluation instances
        nbHeuristics::Union{Int64, Nothing}                     -> number of heuristics evaluated

This evaluator evaluates the heuristics on the same instances along training every evalFreq episodes. Evaluation instances are stored using the attribute 'instances'. 
"""
mutable struct SameInstancesEvaluator <: AbstractEvaluator
    instances::Union{Array{CPModel}, Nothing}
    metrics::Union{Matrix{<:AbstractMetrics}, Nothing} 
    evalFreq::Int64
    nbInstances::Int64
    nbHeuristics::Union{Int64, Nothing}
end

"""
    function SameInstancesEvaluator(valueSelectionArray::Array{H, 1}, generator::AbstractModelGenerator; seed=nothing, evalFreq::Int64 = 50, nbInstances::Int64 = 10, evalTimeOut::Union{Nothing,Int64} = nothing) where H<: ValueSelection

Constructor for SameInstancesEvaluator. In order to generate nbInstances times the same evaluation instance, a seed has to be specified. Otherwise, the instance will be generated randomly. 
"""
function SameInstancesEvaluator(valueSelectionArray::Array{H, 1}, generator::AbstractModelGenerator ; rng::AbstractRNG = MersenneTwister(), evalFreq::Int64 = 50, nbInstances::Int64 = 10, evalTimeOut::Union{Nothing,Int64} = nothing) where H<: ValueSelection
    instances = Array{CPModel}(undef, nbInstances)
    metrics = Matrix{AbstractMetrics}(undef,nbInstances, size(valueSelectionArray,1)) 
    Random.seed!(rand(rng, 0:typemax(Int64)))
    for i in 1:nbInstances
        instances[i] = CPModel()
        fill_with_generator!(instances[i], generator, rng = rng)   #fill_with_generator!(instances[i], generator; rng = rng)

        instances[i].limit.searchingTime = evalTimeOut
        for (j, value) in enumerate(valueSelectionArray)
            metrics[i,j]=BasicMetrics(instances[i],value;meanOver=1)
        end 
    end    
    SameInstancesEvaluator(instances, metrics, max(1,evalFreq), nbInstances, size(valueSelectionArray,1))
end


function setNodesBudget!(evaluator::SameInstancesEvaluator, budget::Int)
    for instance in evaluator.instances
        instance.limit.numberOfNodes = budget
    end
end

function resetNodesBudget!(evaluator::SameInstancesEvaluator)
    for instance in evaluator.instances
        instance.limit.numberOfNodes = nothing
    end
end


function Base.empty!(eval::SameInstancesEvaluator)
    for i in 1:eval.nbInstances
        for j in 1:eval.nbHeuristics
            eval.metrics[i,j]=BasicMetrics(eval.instances[i],eval.metrics[i,j].heuristic; meanOver=1)
        end 
    end
end
"""
    function evaluate(eval::SameInstancesEvaluator, variableHeuristic::AbstractVariableSelection, strategy::S; verbose::Bool=true) where{S<:SearchStrategy}

This function computes one evaluation step. It does a full search using a specific strategy (DFS, RBS ...) for every heuristic stored in eval.metrics and for every instances to be evaluated on. It fills the matrix eval.metrics whose coordinates [i,j] contains the search metric of type <:AbstractMetrics for the i-th evaluation instance and the j-th heuristic. 
"""
function evaluate(eval::SameInstancesEvaluator, variableHeuristic::AbstractVariableSelection, strategy::S; verbose::Bool=true) where{S<:SearchStrategy}
    for j in 1:eval.nbHeuristics
        heuristic = eval.metrics[1,j].heuristic
        print("Switching to agent : ",typeof(heuristic))
        if isa(heuristic, LearnedHeuristic)          #LearnedHeuristic has to be evaluated at each evaluation step as long as the heuristic is updated along the training.
            initsize = length(heuristic.agent.trajectory) 
            testmode!(heuristic, true)
            for i in 1:eval.nbInstances
                model = eval.instances[i]
                reset_model!(model)
    
                dt = @elapsed search!(model, strategy, variableHeuristic, heuristic)
                eval.metrics[i,j](model,dt)
                verbose && println(typeof(heuristic), " evaluated with: ", model.statistics.numberOfNodes, " nodes, taken ", dt, "s, number of solutions found : ", model.statistics.numberOfSolutions)
            end 
            testmode!(heuristic, false)
            @assert length(heuristic.agent.trajectory) == initsize "You have leaks in your evaluation pipeline!"
            
        
        else                                            #BasicHeuristic only needs to be evaluated once, as it is not updated during training. As long as the eval has already been done once, it only repeat the search metrics for each evaluation step; 
            for i in 1:eval.nbInstances
                model = eval.instances[i]
                reset_model!(model)
                if eval.metrics[i,j].nbEpisodes == 0
                dt = @elapsed search!(model, strategy, variableHeuristic, heuristic)
                eval.metrics[i,j](model,dt)            
                verbose && println(typeof(heuristic), " evaluated with: ", model.statistics.numberOfNodes, " nodes, taken ", dt, "s, number of solutions found : ", model.statistics.numberOfSolutions)
                else
                dt,numberOfNodes, numberOfSolutions = repeatlast!(eval.metrics[i,j])
                verbose && println(typeof(heuristic), " evaluated with: ", numberOfNodes, " nodes, taken ", dt, "s, number of solutions found : ", numberOfSolutions)
                end
            end 
        end


    end
end




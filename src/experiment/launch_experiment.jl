using ProgressBars
using TensorBoardLogger, Logging, Random
using Suppressor


function monitorInput()
    # Put STDIN in 'raw mode'
    ccall(:jl_tty_set_mode, Int32, (Ptr{Nothing}, Int32), stdin.handle, true) == 0 || throw("FATAL: Terminal unable to enter raw mode.")
    inputBuffer = Channel{Char}(100)
    @async begin
        while true
            c = read(stdin, Char)
            put!(inputBuffer, c)
        end
    end
    return inputBuffer
end
"""
    launch_experiment!(;
        ValueSelectionArray::Array{ValueSelection, 1}, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nbEpisodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable
)
This functions launch an amount of nbEpisodes problems solving. The problems are created by
the given generator. The strategy used during the CP Search and the variable heuristic used can 
be precised as well. To finish with, the value selection heuristic (eather learned or basic) are 
given to function. Each problem generated will be solved once by every value selection heuristic
given, making it possible to compare them.
All the results of consecutive search during the training is stocked in metricsArray containing a metrics 
for each heuristic (eather learned or basic).  
It is also possible to give an evaluator to compare the evolution of performance of the heuristic on same instances along the search. 
This function is called by `train!` and by `benchmark_solving!`.
Every "evalFreq" episodes, all heuristic are evaluated ( weights are no longer updated during the evaluation).
"""
function launch_experiment!(
    valueSelectionArray::Array{T,1},
    generator::AbstractModelGenerator,
    nbEpisodes::Int64,
    strategy::S1,
    eval_strategy::S2,
    variableHeuristic::AbstractVariableSelection,
    out_solver::Bool,
    verbose::Bool;
    metrics::Union{Nothing,AbstractMetrics}=nothing,
    evaluator::Union{Nothing,AbstractEvaluator}=SameInstancesEvaluator(valueSelectionArray, generator),
    restartPerInstances::Int64,
    rngTraining::AbstractRNG,
    training_timeout=nothing::Union{Nothing,Int},
    eval_every=nothing::Union{Nothing,Int},
    logger=logger,
    nbTrainingPoints=1000,
    device=cpu
) where {T<:ValueSelection,S1,S2<:SearchStrategy}
    nbHeuristics = length(valueSelectionArray)
    #get the type of CPmodel ( does it contains an objective )
    trailer = Trailer()
    model = CPModel(trailer)
    fill_with_generator!(model, generator)
    metricsArray = AbstractMetrics[]
    for j in 1:nbHeuristics
        if !isnothing(metrics)
            push!(metricsArray, metrics(model, valueSelectionArray[j]))
        else
            push!(metricsArray, BasicMetrics(model, valueSelectionArray[j]))
        end
    end

    empty!(model)
    fill_with_generator!(model, generator)
    # false evaluation used to compile the evaluate function before the real one. Doing so prevent distortion on 1st eval computing time
    if !isnothing(evaluator)
        evaluate(evaluator, variableHeuristic, eval_strategy; verbose=verbose)
        empty!(evaluator)
    end
    start_time, train_time = time_ns(), time_ns()
    eval_time, eval_start, eval_end, j = 0, 0, 0, 0
    iter = ProgressBar(1:nbEpisodes)
    for i in iter
        if !isnothing(evaluator)
            if isnothing(eval_every) && (i % evaluator.evalFreq == 1)
                eval_start = time_ns()
                evaluate(evaluator, variableHeuristic, eval_strategy; verbose=verbose)
                GC.gc()
                if !isnothing(logger)
                    with_logger(logger) do
                        for j in 1:nbHeuristics
                            @info "Eval Heuristic " * string(j) Score = Vector(map(x -> x[1], first.(Vector(last.([metric.scores for metric in evaluator.metrics[:, j]])))))
                        end
                    end
                end
                eval_end = time_ns()
                eval_time += eval_end - eval_start
            elseif !isnothing(eval_every) && (train_time - start_time) / 1.0e9 > eval_every * j
                j += 1
                eval_start = time_ns()
                evaluate(evaluator, variableHeuristic, eval_strategy; verbose=verbose)
                GC.gc()
                if !isnothing(logger)
                    with_logger(logger) do
                        for j in 1:nbHeuristics
                            @info "Eval Heuristic " * string(j) Score = Vector(map(x -> x[1], first.(Vector(last.([metric.scores for metric in evaluator.metrics[:, j]])))))
                        end
                    end
                end
                eval_end = time_ns()
                eval_time += eval_end - eval_start
            end
        else
            eval_time = 0
        end
        train_time = time_ns() - eval_time
        !isnothing(training_timeout) && (train_time - start_time) / 1.0e9 > training_timeout && break
        verbose && println(" --- EPISODE: ", i)

        model = CPModel(trailer)
        fill_with_generator!(model, generator; rng=rngTraining)

        for j in 1:nbHeuristics
            reset_model!(model)
            if isa(valueSelectionArray[j], LearnedHeuristic)
                verbose && print("Visited nodes with learnedHeuristic ", j, " : ")
                dt = @elapsed for k in 1:restartPerInstances
                    restart_search!(model)
                    search!(model, strategy, variableHeuristic, valueSelectionArray[j], out_solver=out_solver)
                    verbose && print(model.statistics.numberOfNodesBeforeRestart, ": ", model.statistics.numberOfSolutions, "(", model.statistics.AccumulatedRewardBeforeRestart, ") / ")
                end

                if i % (nbEpisodes / nbTrainingPoints) == 1 || nbEpisodes <= nbTrainingPoints #We want nbTrainingPoints in the Metrics Array
                    metricsArray[j](model, dt)  #adding results in the metrics data structure
                end
                Load_RAM = (Sys.total_memory() - Sys.free_memory()) / Sys.total_memory()

                if device == cpu
                    Load_VRAM = Load_RAM
                else
                    VRAM_status = @capture_out CUDA.memory_status()  #retrieve raw string status
                    VRAM = match(r"\b(?<!\.)(?!0+(?:\.0+)?%)(?:\d|[1-9]\d|100)(?:(?<!100)\.\d+)?%", VRAM_status) #retrieve VRAM allocation percentage
                    VRAM = VRAM.match
                    Load_VRAM = parse(Float64, replace(VRAM, r"%" => "")) / 100
                end

                if !isnothing(logger)
                    with_logger(logger) do
                        @info "Train Heuristic " * string(j) Loss = last(metricsArray[j].loss) Reward = last(metricsArray[j].totalReward) Node_Visited = last(metricsArray[j].nodeVisited) Time = last(metricsArray[j].timeneeded) Score = first(last(metricsArray[j].scores)) Explorer = ReinforcementLearningCore.get_ϵ(valueSelectionArray[j].agent.policy.explorer) Load_RAM = Load_RAM Load_VRAM = Load_VRAM Trajectory_load = length(valueSelectionArray[j].agent.trajectory) Metrics_size = Base.summarysize(metricsArray)
                    end
                end
                verbose && println()
            end
        end
    end

    if !isnothing(evaluator)
        evaluate(evaluator, variableHeuristic, eval_strategy; verbose=verbose)

        return metricsArray, evaluator.metrics
    end

    return metricsArray, []
end
using CPRL
using ReinforcementLearning
const RL = ReinforcementLearning
using Flux
using Statistics

using Plots
gr()


problem_generator = Dict(
    :coloring => CPRL.fill_with_coloring!,
    :filecoloring => CPRL.fill_with_coloring_file!
)

coloring_file_params = Dict(
    "input_file" => "examples/coloring/data/gc_4_1"
)

coloring_params = Dict(
    "nb_nodes" => 15,
    "density" => 2.5
)

fixedGCNargs = CPRL.ArgsFixedOutputGCNLSTM( 
    maxDomainSize= 15, 
    numInFeatures = 21, 
    firstHiddenGCN = 20, 
    secondHiddenGCN = 20, 
    hiddenDense = 20 
) 
numberOfCPNodes = 83

function CPRL.featurize(g::CPRL.CPLayerGraph)
    features = zeros(Float32, nv(g), 21)
    for i in 1:nv(g)
        cp_vertex = CPRL.cpVertexFromIndex(g, i)
        if isa(cp_vertex, CPRL.VariableVertex)
            features[i, 1] = 1.
            if g.cpmodel.objective == cp_vertex.variable
                features[i, 6] = 1.
            end
        end
        if isa(cp_vertex, CPRL.ConstraintVertex)
            features[i, 2] = 1.
            constraint = cp_vertex.constraint
            if isa(constraint, CPRL.NotEqual)
                features[i, 4] = 1.
            end
            if isa(constraint, CPRL.LessOrEqual)
                features[i, 5] = 1.
            end
        end
        if isa(cp_vertex, CPRL.ValueVertex)
            features[i, 3] = 1.
            value = cp_vertex.value
            features[i, 6+value] = 1.
        end
    end
    features
    # features = zeros(Float32, nv(g), nv(g))
    # for i in 1:size(features)[1]
    #     features[i, i] = 1.0f0
    # end
    # features
end

struct IlanReward <: CPRL.AbstractReward end

function CPRL.set_backtracking_reward!(env::CPRL.RLEnv{IlanReward}, model::CPRL.CPModel, current_status::Union{Nothing, Symbol})
    # env.reward += 5
    println("testfinal")
    nothing
end

function CPRL.set_before_next_decision_reward!(env::CPRL.RLEnv{IlanReward}, model::CPRL.CPModel)
    env.reward -= 0
    println("testfinal")
    nothing
end

function CPRL.set_after_decision_reward!(env::CPRL.RLEnv{IlanReward}, model::CPRL.CPModel)
    env.reward = 0
    println("testfinal")
    nothing
end

function CPRL.set_final_reward!(env::CPRL.RLEnv{IlanReward}, model::CPRL.CPModel)
    env.reward += 30/model.statistics.numberOfNodes + 50
    println("testfinal")
    nothing
end
 
state_size = (numberOfCPNodes,fixedGCNargs.numInFeatures + numberOfCPNodes + 1, 1) 

agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = CPRL.CPDQNLearner(
                approximator = RL.NeuralNetworkApproximator(
                    model = CPRL.build_model(CPRL.FixedOutputGCNLSTM, fixedGCNargs),
                    optimizer = ADAM(0.0005f0)
                ),
                target_approximator = RL.NeuralNetworkApproximator(
                    model = CPRL.build_model(CPRL.FixedOutputGCNLSTM, fixedGCNargs),
                    optimizer = ADAM(0.0005f0)
                ),
                loss_func = huber_loss,
                stack_size = nothing,
                γ = 0.999f0,
                batch_size = 1,
                update_horizon = 15,
                min_replay_history = 1,
                update_freq = 10,
                target_update_freq = 50,
            ), 
            # explorer = CPRL.DirectedExplorer(;
                explorer = CPRL.CPEpsilonGreedyExplorer(
                    ϵ_stable = 0.001,
                    kind = :exp,
                    ϵ_init = 1.0,
                    warmup_steps = 0,
                    decay_steps = 1000,
                    step = 1,
                    is_break_tie = false, 
                    #is_training = true,
                )
                # direction = ((values, mask) -> view(keys(values), mask)[1]),
                # directed_steps=1000
            # )
        ),
        trajectory = RL.CircularCompactSARTSATrajectory(
            capacity = 1000, 
            state_type = Float32, 
            state_size = state_size,
            action_type = Int,
            action_size = (),
            reward_type = Float32,
            reward_size = (),
            terminal_type = Bool,
            terminal_size = ()
        ),
        role = :DEFAULT_PLAYER
    )

learnedHeuristic = CPRL.LearnedHeuristic{IlanReward}(agent)

basicHeuristic = CPRL.BasicHeuristic((x) -> CPRL.minimum(x.domain))

function selectNonObjVariable(model::CPRL.CPModel)
    selectedVar = nothing
    minSize = typemax(Int)
    for (k, x) in model.variables
        if length(x.domain) > 1 && length(x.domain) < minSize# && k != "numberOfColors"
            selectedVar = x
            minSize = length(x.domain)
        end
    end
    # @assert !isnothing(selectedVar)
    if isnothing(selectedVar)
        return model.variables["numberOfColors"]
    end
    return selectedVar
end

maxNumOfEpisodes = 4000

meanNodeVisited = Array{Float32}(undef, maxNumOfEpisodes)
meanNodeVisitedBasic = Array{Float32}(undef, maxNumOfEpisodes)
nodeVisitedBasic = Array{Int64}(undef, maxNumOfEpisodes)
nodeVisitedLearned = Array{Int64}(undef, maxNumOfEpisodes)

meanOver = 50
sum = 0
function metricsFun(;kwargs...)
    i = kwargs[:episode]
    if kwargs[:heuristic] == learnedHeuristic
        currentNodeVisited = kwargs[:nodeVisited]
        nodeVisitedLearned[i] = currentNodeVisited

        currentMean = 0.
        if i <= meanOver
            currentMean = mean(nodeVisitedLearned[1:i])
        else
            currentMean = mean(nodeVisitedLearned[(i-meanOver+1):i])
        end
        meanNodeVisited[i] = currentMean
    else
        currentNodeVisited = kwargs[:nodeVisited]
        nodeVisitedBasic[i] = currentNodeVisited

        currentMean = 0.
        if i <= meanOver
            currentMean = mean(nodeVisitedBasic[1:i])
        else
            currentMean = mean(nodeVisitedBasic[(i-meanOver+1):i])
        end
        meanNodeVisitedBasic[i] = currentMean
    end
end



function trytrain(nepisodes::Int)
    
    bestsolutions, nodevisited = CPRL.train!(
        valueSelectionArray=[learnedHeuristic, basicHeuristic], 
        problem_type=:coloring,
        problem_params=coloring_params,
        nb_episodes=nepisodes,
        strategy=CPRL.DFSearch,
        variableHeuristic=selectNonObjVariable,
        metricsFun=metricsFun,
        verbose=false
    )
    # println(bestsolutions)
    # nodevisited = Array{Any}([35, 51])
    # nodevisited = convert(Array{Int}, nodevisited)
    # println(nodevisited)

    
    # plot 
    x = 1:nepisodes

    p = plot(x, 
            [nodeVisitedLearned[1:nepisodes] meanNodeVisited[1:nepisodes] nodeVisitedBasic[1:nepisodes] meanNodeVisitedBasic[1:nepisodes] (nodeVisitedLearned-nodeVisitedBasic)[1:nepisodes] (meanNodeVisited-meanNodeVisitedBasic)[1:nepisodes]], 
            xlabel="Episode", 
            ylabel="Number of nodes visited", 
            label = ["Learned" "mean/$meanOver Learned" "Basic" "mean/$meanOver Basic" "Delta" "Mean Delta"],
            ylims = (-50,300)
            )
    display(p)
    

    p = plot(x, 
            [(meanNodeVisited-meanNodeVisitedBasic)[1:2000]], 
            xlabel="Episode", 
            ylabel="Number of nodes visited", 
            label = "Mean Delta",
            ylims = (-50,300)
            )
    return nodeVisitedLearned, meanNodeVisited, nodeVisitedBasic
end



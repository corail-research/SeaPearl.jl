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

knapsack_params = Dict(
    "nb_items" => 5,
    "max_weight" => 10,
    "correlation" => 1
)


numberOfFeatures = 10

function CPRL.featurize(g::CPRL.CPLayerGraph) 
    features = zeros(Float32, nv(g), numberOfFeatures) 
    for i in 1:nv(g) 
        cp_vertex = CPRL.cpVertexFromIndex(g, i) 
        if isa(cp_vertex, CPRL.VariableVertex) 
            variable = cp_vertex.variable 
            features[i, 1] = 1. 
            if g.cpmodel.objective == variable
                features[i, 2] = 1. 
            end 
            
            if isa(variable, CPRL.IntVarViewOpposite)
                features[i, 3] = 1. 
            end
            if isa(variable, CPRL.IntVarViewMul)
                features[i, 4] = 1. 
                features[i, 5] = variable.a 
            end
        end 
        if isa(cp_vertex, CPRL.ConstraintVertex) 
            features[i, 6] = 1. 
            constraint = cp_vertex.constraint 
            if isa(constraint, CPRL.SumToZero) 
                features[i, 7] = 1. 
            end 
            if isa(constraint, CPRL.LessOrEqualConstant) 
                features[i, 8] = 1. 
            end 
        end 
        if isa(cp_vertex, CPRL.ValueVertex) 
            features[i, 9] = 1. 
            value = cp_vertex.value 
            features[i, 10] = value/knapsack_params["max_weight"]
        end 
    end 
    features 
    # features = zeros(Float32, nv(g), nv(g)) 
    # for i in 1:size(features)[1] 
    #     features[i, i] = 1.0f0 
    # end 
    # features 
end 


fixedGCNargs = CPRL.ArgsFixedOutputGCN( 
    maxDomainSize= 15, 
    numInFeatures = numberOfFeatures, 
    firstHiddenGCN = 20, 
    secondHiddenGCN = 20, 
    hiddenDense = 20 
) 

maxNumberOfCPnodes = 200
state_size = (maxNumberOfCPnodes,fixedGCNargs.numInFeatures + maxNumberOfCPnodes + 2, 1) 

agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = CPRL.CPDQNLearner(
                approximator = RL.NeuralNetworkApproximator(
                    model = CPRL.build_model(CPRL.FixedOutputGCN, fixedGCNargs),
                    optimizer = ADAM(0.0005f0)
                ),
                target_approximator = RL.NeuralNetworkApproximator(
                    model = CPRL.build_model(CPRL.FixedOutputGCN, fixedGCNargs),
                    optimizer = ADAM(0.0005f0)
                ),
                loss_func = huber_loss,
                stack_size = nothing,
                γ = 0.999f0,
                batch_size = 1,
                update_horizon = 1,
                min_replay_history = 1,
                update_freq = 50,
                target_update_freq = 200,
                seed = 22,
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
            capacity = 3000, 
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

learnedHeuristic = CPRL.LearnedHeuristic(agent, maxNumberOfCPnodes)

basicHeuristic = CPRL.BasicHeuristic((x) -> CPRL.maximum(x.domain))

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
        problem_type=:knapsack,
        problem_params=knapsack_params,
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
    return nodeVisitedLearned, meanNodeVisited, nodeVisitedBasic
end



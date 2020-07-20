using CPRL
using ReinforcementLearning
const RL = ReinforcementLearning
using Flux
using GeometricFlux

using Plots
gr()

####
include("felix_utils/utils.jl")
####

coloring_generator = CPRL.GraphColoringGenerator(10, 1.4)

numInFeatures = 16
numberOfCPNodes = 1 + floor(Int64, coloring_generator.nb_nodes * ( 3 + coloring_generator.density ))
#numberOfCPNodes = 141

state_size = (numberOfCPNodes, numInFeatures + numberOfCPNodes + 2 + 1, 1)

agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = CPRL.CPDQNLearner(
                approximator = RL.NeuralNetworkApproximator(
                    model = CPRL.FlexGNN(
                        graphChain = Flux.Chain(
                            GeometricFlux.GCNConv(numInFeatures => 20),
                            GeometricFlux.GCNConv(20 => 20),
                        ),
                        nodeChain = Flux.Chain(
                            Flux.Dense(20, 20),
                        ),
                        outputLayer = Flux.Dense(20, 10)
                    ),
                    optimizer = ADAM(0.0005f0)
                ),
                target_approximator = RL.NeuralNetworkApproximator(
                    model = CPRL.FlexGNN(
                        graphChain = Flux.Chain(
                            GeometricFlux.GCNConv(numInFeatures => 20),
                            GeometricFlux.GCNConv(20 => 20),
                        ),
                        nodeChain = Flux.Chain(
                            Flux.Dense(20, 20),
                        ),
                        outputLayer = Flux.Dense(20, 10)
                    ),
                    optimizer = ADAM(0.0005f0)
                ),
                loss_func = huber_loss,
                stack_size = nothing,
                γ = 0.9999f0,
                batch_size = 1, #32,
                update_horizon = 25,
                min_replay_history = 1,
                update_freq = 10,
                target_update_freq = 200,
                seed = 22,
            ), 
            explorer = CPRL.CPEpsilonGreedyExplorer(
                ϵ_stable = 0.001,
                kind = :exp,
                ϵ_init = 1.0,
                warmup_steps = 0,
                decay_steps = 1000,
                step = 1,
                is_break_tie = false, 
                #is_training = true,
                seed = 33
            )
        ),
        trajectory = RL.CircularCompactSARTSATrajectory(
            capacity = 3000, 
            state_type = Float32, 
            state_size = state_size,#(46, 93, 1),
            action_type = Int,
            action_size = (),
            reward_type = Float32,
            reward_size = (),
            terminal_type = Bool,
            terminal_size = ()
        ),
        role = :DEFAULT_PLAYER
    )

learnedHeuristic = CPRL.LearnedHeuristic{CPRL.DefaultStateRepresentation, InspectReward, CPRL.FixedOutput}(agent)

selectMin(x::CPRL.IntVar) = CPRL.minimum(x.domain)
selectMax(x::CPRL.IntVar) = CPRL.maximum(x.domain)
selectRandom(x::CPRL.IntVar) = rand(collect(x.domain))

heuristic_min = CPRL.BasicHeuristic(selectMin)
heuristic_max = CPRL.BasicHeuristic(selectMax)
heuristic_rand = CPRL.BasicHeuristic(selectRandom)

function selectNonObjVariable(model::CPRL.CPModel)
    selectedVar = nothing
    minSize = typemax(Int)
    for (k, x) in model.variables
        if length(x.domain) > 1 && length(x.domain) < minSize #&& k != "numberOfColors"
            selectedVar = x
            minSize = length(x.domain)
        end
    end
    # @assert !isnothing(selectedVar)
    return selectedVar
end

function selectRandVariable(model::CPRL.CPModel)
    vars = collect(values(model.variables))
    filter!(x -> length(x.domain) > 1, vars)
    return rand(vars)
end

############# TRAIN

bestsolutions, nodevisited, timeneeded = CPRL.train!(
    valueSelectionArray=[learnedHeuristic, heuristic_min], 
    #valueSelectionArray=learnedHeuristic,
    generator=coloring_generator,
    nb_episodes=400,
    strategy=CPRL.DFSearch,
    variableHeuristic=selectRandVariable,
    verbose = false
)

# plot 
a, b = size(nodevisited)
x = 1:a

p1 = plot(x, nodevisited, xlabel="Episode", ylabel="Number of nodes visited", ylims = [0, 200])

#display(p1)

############# BENCHMARK

bestsolutions, nodevisited, timeneeded = CPRL.benchmark_solving(
    valueSelectionArray=[learnedHeuristic, heuristic_min], 
    #valueSelectionArray=learnedHeuristic,
    generator=coloring_generator,
    nb_episodes=200,
    strategy=CPRL.DFSearch,
    variableHeuristic=selectRandVariable,
    verbose = false
)

# plot 
a, b = size(nodevisited)
x = 1:a

p2 = plot(x, nodevisited, xlabel="Episode", ylabel="Number of nodes visited", ylims = [0, 200])
p3 = plot(x, timeneeded, xlabel="Episode", ylabel="Time needed", ylims = [0, 0.01])


p = plot(p1, p2, p3, legend = false, layout = (3, 1))

display(p)

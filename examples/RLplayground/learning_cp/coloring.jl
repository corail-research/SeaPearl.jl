using CPRL
using ReinforcementLearning
const RL = ReinforcementLearning
using Flux

using Plots
gr()

problem_generator = Dict(
    :coloring => CPRL.fill_with_coloring!
)

coloring_params = Dict(
    "nb_nodes" => 10,
    "density" => 1.5
)

agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = CPRL.CPDQNLearner(
                approximator = RL.NeuralNetworkApproximator(
                    model = Chain(
                        Flux.flatten,
                        Dense(46*93, 1000, Flux.relu),
                        Dense(1000, 100, Flux.relu),
                        Dense(100, 10, Flux.relu)
                    ),
                    optimizer = ADAM(0.0005f0)
                ),
                target_approximator = RL.NeuralNetworkApproximator(
                    model = Chain(
                        Flux.flatten,
                        Dense(46*93, 1000, Flux.relu, initW = seed_glorot_uniform(seed = 17)),
                        Dropout(0.2),
                        Dense(1000, 100, Flux.relu, initW = seed_glorot_uniform(seed = 23)),
                        Dropout(0.2),
                        Dense(100, 10, Flux.relu, initW = seed_glorot_uniform(seed = 39))
                    ),
                    optimizer = ADAM(0.0005f0)
                ),
                loss_func = huber_loss,
                stack_size = nothing,
                γ = 0.99f0,
                batch_size = 32,
                update_horizon = 1,
                min_replay_history = 1,
                update_freq = 1,
                target_update_freq = 50,
                seed = 22,
            ), 
            explorer = CPRL.CPEpsilonGreedyExplorer(
                ϵ_stable = 0.01,
                kind = :exp,
                ϵ_init = 1.0,
                warmup_steps = 0,
                decay_steps = 500,
                step = 1,
                is_break_tie = false, 
                #is_training = true,
                seed = 33
            )
        ),
        trajectory = RL.CircularCompactSARTSATrajectory(
            capacity = 500, 
            state_type = Float32, 
            state_size = (46, 93, 1),
            action_type = Int,
            action_size = (),
            reward_type = Float32,
            reward_size = (),
            terminal_type = Bool,
            terminal_size = ()
        ),
        role = :DEFAULT_PLAYER
    )

learnedHeuristic = CPRL.LearnedHeuristic(agent)

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

bestsolutions, nodevisited = CPRL.train!(
    valueSelectionArray=[learnedHeuristic, heuristic_min, heuristic_max, heuristic_rand], 
    #valueSelectionArray=learnedHeuristic,
    problem_type=:coloring,
    problem_params=coloring_params,
    nb_episodes=10,
    strategy=CPRL.DFSearch,
    variableHeuristic=selectNonObjVariable
)

println(bestsolutions)
println(nodevisited)


"""
x = 1:length(nodevisited)
p = plot(x, nodevisited, xlabel="Episode", ylabel="Number of nodes visited", ylims = [0, 180])
"""
# plot 
a, b = size(nodevisited)
x = 1:a

p1 = plot(x, nodevisited[:, 1], xlabel="Episode", ylabel="Number of nodes visited", ylims = [0, 180])
if b >= 2
    for i in 2:b
        plot!(p1, x, nodevisited[:, b])
    end
end

display(p1)

########################

bestsolutions, nodevisited = CPRL.benchmark_solving(
    valueSelectionArray=[learnedHeuristic, heuristic_min, heuristic_max, heuristic_rand], 
    #valueSelectionArray=learnedHeuristic,
    problem_type=:coloring,
    problem_params=coloring_params,
    nb_episodes=10,
    strategy=CPRL.DFSearch,
    variableHeuristic=selectNonObjVariable
)

println(bestsolutions)
println(nodevisited)


"""
x = 1:length(nodevisited)
p = plot(x, nodevisited, xlabel="Episode", ylabel="Number of nodes visited", ylims = [0, 180])
"""
# plot 
a, b = size(nodevisited)
x = 1:a

p2 = plot(x, nodevisited[:, 1], xlabel="Episode", ylabel="Number of nodes visited", ylims = [0, 180])
if b >= 2
    for i in 2:b
        plot!(p2, x, nodevisited[:, b])
    end
end

p = plot(p1, p2, layout = 2)

display(p)
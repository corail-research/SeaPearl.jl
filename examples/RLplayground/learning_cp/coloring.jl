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
            learner = RL.DQNLearner(
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
                        Dense(46*93, 1000, Flux.relu),
                        Dense(1000, 100, Flux.relu),
                        Dense(100, 10, Flux.relu)
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
            explorer = RL.EpsilonGreedyExplorer(
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
basicHeuristic = CPRL.BasicHeuristic(selectMin)

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

bestsolutions, nodevisited = CPRL.multi_train!(
    ValueSelectionArray=[learnedHeuristic, basicHeuristic], 
    #learnedHeuristic=learnedHeuristic,
    problem_type=:coloring,
    problem_params=coloring_params,
    nb_episodes=60,
    strategy=CPRL.DFSearch,
    variableHeuristic=selectNonObjVariable
)

println(bestsolutions)
println(nodevisited)


"""
x = 1:length(nodevisited)

p = plot(x, nodevisited, xlabel="Episode", ylabel="Number of nodes visited")


"""
# plot 
x = 1:length(nodevisited[:, 1])

p = plot(x, nodevisited[:, 1], xlabel="Episode", ylabel="Number of nodes visited")
plot!(p, x, nodevisited[:, 2])


display(p)
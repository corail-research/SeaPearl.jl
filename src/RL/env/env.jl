include("searchmetrics.jl")

"""
    abstract type AbstractReward end

Used to customize the reward function. If you want to use your own reward, you have to create a struct
(called `CustomReward` for example) and define the following methods:
- set_backtracking_reward!(env::RLEnv{CustomReward}, model::CPModel, current_status::Union{Nothing, Symbol})
- set_before_next_decision_reward!(env::RLEnv{CustomReward}, model::CPModel)
- set_after_decision_reward!(env::RLEnv{CustomReward}, model::CPModel)
- set_final_reward!(env::RLEnv{CustomReward}, symbol::Symbol)

Then, when creating the `LearnedHeuristic`, you define it using `LearnedHeuristic{CustomReward}(agent::RL.Agent)`
and your functions will be called instead of the default ones.
"""  

abstract type AbstractReward end

"""
    RLEnv

Implementation of the RL.AbstractEnv type coming from ReinforcementLearning's interface.
The RLEnv does not need t (step) and action as they are usually useful to control what is 
happening and this role is taken by the CP part in our framework. 

We will keep the env.done for now for convenience reasons (to stay near enough to the RL 
framework in order to be able to use its useful functions)
"""
mutable struct RLEnv{R<:AbstractReward} <: RL.AbstractEnv 
    action_space::RL.DiscreteSpace{Array{Int64,1}}
    state::CPGraph
    action::Int64
    reward::Float64
    done::Bool
    rng::Random.MersenneTwister # random number generator
    cpnodes_max::Union{Nothing, Int64}
    search_metrics::SearchMetrics
end

"""
    RLEnv(model::CPModel, seed = nothing, cpnodes_max=nothing)

Construct the RLEnv thanks to the informations which are in the CPModel.
"""
function RLEnv{R}(cpmodel::CPModel, seed = nothing; cpnodes_max=nothing) where (R <: AbstractReward)
    if isnothing(cpmodel.RLRep)
        cpmodel.RLRep = CPLayerGraph(cpmodel)
    end
    # construct the action_space
    variables = collect(values(cpmodel.variables))
    valuesOfVariables = sort(arrayOfEveryValue(variables))
    action_space = RL.DiscreteSpace(valuesOfVariables)

    # get the random number generator
    rng = MersenneTwister(seed)

    env = RLEnv{R}(
        action_space,
        CPGraph(cpmodel, 0), # use a fake variable index
        1,
        0,
        false,  
        rng,
        cpnodes_max,
        SearchMetrics(cpmodel)
        )
    
    env
end

RLEnv(cpmodel::CPModel, seed = nothing) = RLEnv{DefaultReward}(cpmodel, seed)


include("reward.jl")

"""
    set_done!(env::RLEnv, done::Bool)

Change the "done" attribute of the env. This is compulsory as used in the buffer
for the training.
"""
function set_done!(env::RLEnv, done::Bool)
    env.done = done
    nothing
end

"""
    set_metrics!(env::RLEnv, model::CPModel, symbol::Union{Nothing, Symbol}) 

Call set_metrics!(::SearchMetrics, ...) on env.search_metrics to simplify synthax.
"""
set_metrics!(env::RLEnv, model::CPModel, symbol::Union{Nothing, Symbol}) = set_metrics!(env.search_metrics, model, symbol)

"""
    sync!(env::RLEnv, cpmodel::CPModel, x::AbstractIntVar)

Synchronize the env with the CPModel.
"""
function sync_state!(env::RLEnv, cpmodel::CPModel, x::AbstractIntVar)
    if isnothing(cpmodel.RLRep)
        cpmodel.RLRep = CPLayerGraph(cpmodel)
    end
    update_graph!(env.state, cpmodel.RLRep, x)
    nothing 
end

"""
    observe(::RLEnv)

Return what is observe by the agent at each stage. It contains (among others) the
rewards, thus it might be a function to modify during our experiments. It also contains the 
legal_actions !

To do : Need to change the reward
To do : Need to change the legal actions
"""
function observe!(env::RLEnv, model::CPModel, x::AbstractIntVar)
    # get legal_actions_mask
    legal_actions_mask = [value in x.domain for value in env.action_space]

    # compute legal actions
    legal_actions = env.action_space.span[legal_actions_mask]

    reward = env.reward
    # Initialize reward for the next state: not compulsory with DefaultReward, but maybe useful in case the user forgets it
    env.reward = 0

    # synchronize state: we could delete env.state, we do not need it 
    sync_state!(env, model, x)

    state = to_array(env.state, env.cpnodes_max)
    state = reshape(state, size(state)..., 1)
    # println("reward", reward)
    
    # return the observation as a named tuple (useful for interface understanding)
    return (reward = reward, terminal = env.done, state = state, legal_actions = legal_actions, legal_actions_mask = legal_actions_mask)
end

"""
    Random.seed!(env::RLEnv, seed)

We want our experiences to be reproducible, thus we provide this function to reseed the random
number generator. rng will give a reproducible sequence of numbers if and only if a seed is provided.
"""
Random.seed!(env::RLEnv, seed) = Random.seed!(env.rng, seed)

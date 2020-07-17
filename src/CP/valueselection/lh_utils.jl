
Flux.testmode!(lh::LearnedHeuristic, mode = true) = Flux.testmode!(lh.agent, mode) 

function update_with_cpmodel!(lh::LearnedHeuristic, model::CPModel)
    if isnothing(model.RLRep)
        model.RLRep = CPLayerGraph(model)
    end
    # construct the action_space
    variables = collect(values(model.variables))
    valuesOfVariables = sort(arrayOfEveryValue(variables))

    lh.action_space = RL.DiscreteSpace(valuesOfVariables)
    lh.current_state = CPGraph(model, 0)
    lh.current_reward = 0
    lh.search_metrics = SearchMetrics(model)

    lh
end

include("reward.jl")

"""
    sync!(lh::LearnedHeuristic, model::CPModel, x::AbstractIntVar)

Synchronize the env with the CPModel.
"""
function sync_state!(lh::LearnedHeuristic, model::CPModel, x::AbstractIntVar)
    if isnothing(model.RLRep)
        model.RLRep = CPLayerGraph(model)
    end
    update_graph!(lh.current_state, model.RLRep, x)
    nothing 
end

function get_observation!(lh::LearnedHeuristic, model::CPModel, x::AbstractIntVar, done = false)
    # get legal_actions_mask
    legal_actions_mask = [value in x.domain for value in lh.action_space]

    # compute legal actions
    legal_actions = lh.action_space.span[legal_actions_mask]

    reward = lh.current_reward
    # Initialize reward for the next state: not compulsory with DefaultReward, but maybe useful in case the user forgets it
    lh.current_reward = 0

    # synchronize state: we could delete env.state, we do not need it 
    sync_state!(lh, model, x)

    state = to_array(lh.current_state, lh.cpnodes_max)
    state = reshape(state, size(state)..., 1)
    # println("reward", reward)
    
    # return the observation as a named tuple (useful for interface understanding)
    return (reward = reward, terminal = done, state = state, legal_actions = legal_actions, legal_actions_mask = legal_actions_mask)
end

"""
    set_metrics!(PHASE::T, lh::LearnedHeuristic, model::CPModel, symbol::Union{Nothing, Symbol}, x::Union{Nothing, AbstractIntVar}) where T <: LearningPhase 

Call set_metrics!(::SearchMetrics, ...) on env.search_metrics to simplify synthax.
Could also add it to basicheuristic !
"""
function set_metrics!(PHASE::T, lh::LearnedHeuristic, model::CPModel, symbol::Union{Nothing, Symbol}, x::Union{Nothing, AbstractIntVar}) where T <: LearningPhase
    set_metrics!(PHASE, lh.search_metrics, model, symbol, x::Union{Nothing, AbstractIntVar})
end

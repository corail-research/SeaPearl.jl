
"""
    Flux.testmode!(lh::LearnedHeuristic, mode = true)

Make it possible to change the mode of the LearnedHeuristic: training or testing. This makes sure
you stop updating the weights or the approximator once the training is done. It is used at the beginning
of the `train!` function to make sure it's training and changed automatically at the end of it but a user can 
manually change the mode again if he wants.
"""
Flux.testmode!(lh::LearnedHeuristic, mode = true) = Flux.testmode!(lh.agent, mode) 

"""
    update_with_cpmodel!(lh::LearnedHeuristic{SR, R, A}, model::CPModel)

This function initializes the fields of a LearnedHeuristic which are useful to do reinforcement learning 
and which depend on the CPModel considered. It is called at the beginning of the `search!` function (in the 
InitializingPhase).
"""
function update_with_cpmodel!(lh::LearnedHeuristic{SR, R, A}, model::CPModel) where {
    SR <: AbstractStateRepresentation, 
    R <: AbstractReward, 
    A <: ActionOutput
}

    # construct the action_space
    valuesOfVariables = sort(branchable_values(model))

    lh.action_space = RL.DiscreteSpace(valuesOfVariables)
    # state rep construction
    lh.current_state = SR(model)

    # create and initialize the reward
    lh.reward = R(model)

    lh.search_metrics = SearchMetrics(model)

    lh
end

"""
    sync!(lh::LearnedHeuristic, model::CPModel, x::AbstractIntVar)

Synchronize the environment part of the LearnedHeuristic with the CPModel.
"""
function sync_state!(lh::LearnedHeuristic, model::CPModel, x::AbstractIntVar)
    update_representation!(lh.current_state, model, x)
    nothing 
end

"""
    get_observation!(lh::LearnedHeuristic, model::CPModel, x::AbstractIntVar, done = false)

This function retrieve all the elements that are useful for doing reinforcement learning. 
- The reward, which has been incremented through the set_reward!(PHASE, ...) functions. 
- The terminal boolean (is the episode done or not)
- The current state, which is the StateRepresentation of the CPModel at this stage of the solving.
This state is what will then be given to the agent to make him proposed an action (a value to assign.)
- The legal_actions & legal_actions_mask used to make sure the agent won't propose a value which isn't 
in the domain of the variable we're branching on. 

The result is given as a namedtuple for convenience with ReinforcementLearning.jl interface. 
"""
function get_observation!(lh::LearnedHeuristic, model::CPModel, x::AbstractIntVar, done = false)
    # get legal_actions_mask
    legal_actions_mask = [value in x.domain for value in lh.action_space]

    # compute legal actions
    legal_actions = lh.action_space.span[legal_actions_mask]

    reward = lh.reward.value
    # Initialize reward for the next state: not compulsory with DefaultReward, but maybe useful in case the user forgets it
    lh.reward.value = 0

    # synchronize state: we could delete env.state, we do not need it 
    sync_state!(lh, model, x)

    state = to_arraybuffer(lh.current_state, lh.cpnodes_max)
    # println("reward", reward)
    
    # return the observation as a named tuple (useful for interface understanding)
    return CPEnv(reward, done, state, legal_actions, legal_actions_mask)
end

struct CPEnv <: AbstractEnv
    reward
    terminal
    state
    legal_actions
    legal_actions_mask
end

RLBase.get_actions(env::CPEnv) = env.legal_actions
RLBase.get_legal_actions(env::CPEnv) = env.legal_actions
RLBase.get_legal_actions_mask(env::CPEnv) = env.legal_actions_mask
RLBase.get_reward(env::CPEnv) = env.reward
RLBase.get_terminal(env::CPEnv) = env.terminal
RLBase.get_state(env::CPEnv) = env.state
ActionStyle(CPEnv) = FULL_ACTION_SET
"""
    set_metrics!(PHASE::T, lh::LearnedHeuristic, model::CPModel, symbol::Union{Nothing, Symbol}, x::Union{Nothing, AbstractIntVar}) where T <: LearningPhase 

Call set_metrics!(::SearchMetrics, ...) on env.search_metrics to simplify synthax.
Could also add it to basicheuristic !
"""
function set_metrics!(PHASE::T, lh::LearnedHeuristic, model::CPModel, symbol::Union{Nothing, Symbol}, x::Union{Nothing, AbstractIntVar}) where T <: LearningPhase
    set_metrics!(PHASE, lh.search_metrics, model, symbol, x::Union{Nothing, AbstractIntVar})
end

wears_mask(valueSelection::LearnedHeuristic) = wears_mask(valueSelection.agent.policy.learner.approximator.model)



"""
    from_order_to_id(state::AbstractArray, value_order::Int64)

Return the ids of the valid indexes from the Array representation of the AbstractStateRepresentation. Used to be able to work with 
ActionOutput of variable size (VariableOutput).
"""
function from_order_to_id(state::AbstractArray, value_order::Int64, SR::Type{<:AbstractStateRepresentation})
    value_vector = state[:, end]
    valid_indexes = findall((x) -> x == 1, value_vector)
    return valid_indexes[value_order]
end

"""
    action_to_value(vs::LearnedHeuristic{SR, R, VariableOutput}, action::Int64, state::AbstractArray, model::CPModel)

Mapping action taken to corresponding value when handling VariableOutput type of ActionOutput.
"""
function action_to_value(vs::LearnedHeuristic{SR, R, VariableOutput}, action::Int64, state::AbstractArray, model::CPModel) where {
    SR <: DefaultStateRepresentation,
    R <: AbstractReward
}
    value_id = from_order_to_id(state, action, SR)
    cp_vertex = cpVertexFromIndex(vs.current_state.cplayergraph, value_id)
    @assert isa(cp_vertex, ValueVertex)
    return cp_vertex.value
end

function action_to_value(vs::LearnedHeuristic{SR, R, VariableOutput}, action::Int64, state::AbstractArray, model::CPModel) where {
    SR <: TsptwStateRepresentation,
    R <: AbstractReward
}
    return from_order_to_id(state, action, SR)
end

"""
    action_to_value(vs::LearnedHeuristic{SR, R, FixedOutput}, action::Int64, state::AbstractArray, model::CPModel)

Mapping index of Q-value vector to value in the action space when using a FixedOutput.
"""
function action_to_value(vs::LearnedHeuristic{SR, R, FixedOutput}, action::Int64, state::AbstractArray, model::CPModel) where {
    SR <: AbstractStateRepresentation,
    R <: AbstractReward
}
    return vs.action_space.span[action]
end

"""
    function branchable_values(cpmodel::CPModel)

Return an array of all possible values taken by the variables we can branch on.
"""
function branchable_values(cpmodel::CPModel)
    setOfValues = Set{Int}()
    for (k, x) in branchable_variables(cpmodel)
        for value in x.domain
            push!(setOfValues, value)
        end
    end
    return collect(setOfValues)
end

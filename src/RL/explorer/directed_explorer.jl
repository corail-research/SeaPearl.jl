export DirectedExplorer

using Random
using Distributions: Categorical
using Flux

using ReinforcementLearningBase
const RLBase = ReinforcementLearningBase

"""
    DirectedExplorer(;kwargs...)
    DirectedExplorer(explorer) -> DirectedExplorer{:linear}(; explorer = explorer)

> Directed explorer, will follow the direction given for `directed_steps` steps, and then follow the given explorer.


# Keywords

- `explorer::CPEpsilonGreedyExplorer`: Defines what policy to follow after the directed steps
- `direction::Function: The direction you want to follow, must be able to take only values, or values and mask.
- `directed_steps::Int = 100`: The number of directed steps before using the explorer.
- `step::Int = 1`: record the current step.
- `seed=nothing`: set the seed of internal RNG.
- `is_training=true`, in training mode, `step` will not be updated.

"""
mutable struct DirectedExplorer{R} <: RL.AbstractExplorer
    explorer::CPEpsilonGreedyExplorer
    direction::Function
    directed_steps::Int
    step::Int
    rng::R
    is_training::Bool
end

function DirectedExplorer(;
    explorer,
    direction,
    directed_steps=100,
    step=1,
    is_training = true,
    seed = nothing,
)
    rng = MersenneTwister(seed)
    DirectedExplorer{typeof(rng)}(
        explorer,
        direction,
        directed_steps,
        step,
        rng,
        is_training,
    )
end

function Flux.testmode!(p::DirectedExplorer, mode = true)
    p.is_training = !mode
    Flux.testmode!(p.explorer, mode)
end

DirectedExplorer(explorer, direction; kwargs...) = DirectedExplorer(; explorer = explorer, direction=direction, kwargs...)

"""
    (s::EpsilonGreedyExplorer)(values; step) where T

!!! note
    If multiple values with the same maximum value are found.
    Then a random one will be returned!

    `NaN` will be filtered unless all the values are `NaN`.
    In that case, a random one will be returned.
"""
function (s::DirectedExplorer{<:Any})(values)
    s.is_training && (s.step += 1)
    if s.step > s.directed_steps
        return s.explorer(values)
    end
    s.direction(values)
end

function (s::DirectedExplorer{<:Any})(values, mask)
    s.is_training && (s.step += 1)
    # println("s.step", s.step)
    # println("s.directed_steps", s.directed_steps)
    if s.step > s.directed_steps
        return s.explorer(values, mask)
    end
    # println("mask", mask)
    s.direction(values, mask)
end

Random.seed!(s::DirectedExplorer, seed) = Random.seed!(s.rng, seed)

"""
    get_prob(s::EpsilonGreedyExplorer, values) ->Categorical
    get_prob(s::EpsilonGreedyExplorer, values, mask) ->Categorical

Return the probability of selecting each action given the estimated `values` of each action.
"""
function RLBase.get_prob(s::DirectedExplorer{<:Any}, values)
    if s.step > s.directed_steps
        return RLBase.get_prob(s.explorer, values)
    end
    n = length(values)
    probs = zeros(n)
    probs[s.direction(values)] = 1.
    Categorical(probs)
end

function RLBase.get_prob(s::DirectedExplorer{<:Any}, values, action::Integer)
    if s.step > s.directed_steps
        return RLBase.get_prob(s.explorer, values, action)
    end
    s.direction(values) == action ? 1. : 0.
end

function RLBase.get_prob(s::DirectedExplorer{<:Any}, values, mask)
    if s.step > s.directed_steps
        return RLBase.get_prob(s.explorer, values, mask)
    end
    n = length(values)
    probs = zeros(n)
    probs[s.direction(values, mask)] = 1.
    Categorical(probs)
end

RLBase.reset!(s::DirectedExplorer) = s.step = 1

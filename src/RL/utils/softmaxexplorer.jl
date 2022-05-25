"""
    This struct provides an alternative explorer to epsilon-greedy, using softmax with temperature.
"""

mutable struct SoftmaxTDecayExplorer{R} <: RL.AbstractExplorer
    T_stable::Float64
    T_init::Float64
    warmup_steps::Int
    decay_steps::Int
    step::Int
    rng::R
    is_training::Bool
end

function SoftmaxTDecayExplorer(;
    T_stable = 0.2,
    T_init = 5.0,
    warmup_steps = 0,
    decay_steps = 0,
    step = 1,
    is_training = true,
    rng = Random.GLOBAL_RNG,
)
    SoftmaxTDecayExplorer{typeof(rng)}(
        T_stable,
        T_init,
        warmup_steps,
        decay_steps,
        step,
        rng,
        is_training,
    )
end

function get_T(s::SoftmaxTDecayExplorer, step)
    if step <= s.warmup_steps
        s.T_init
    elseif step >= (s.warmup_steps + s.decay_steps)
        s.T_stable
    else
        steps_left = s.warmup_steps + s.decay_steps - step
        s.T_stable + steps_left / s.decay_steps * (s.T_init - s.T_stable)
    end
end

function (s::SoftmaxTDecayExplorer)(values, mask)
    T = get_T(s, s.step)
    s.is_training && (s.step += 1)
    legal_actions = [i for i in 1:length(mask) if mask[i]]
    legal_q_values = values[legal_actions]
    exp_T = exp.(legal_q_values./T)
    sum_exp_T = sum(exp_T)
    prob_distrib = ProbabilityWeights(exp_T./sum_exp_T)
    sampled_idx = sample(s.rng, 1:length(legal_q_values), prob_distrib)
    return legal_actions[sampled_idx]
end

function (s::SoftmaxTDecayExplorer)(values)
    T = get_T(s, s.step)
    s.is_training && (s.step += 1)
    exp_T = exp.(legal_q_values./T)
    sum_exp_T = sum(exp_T)
    prob_distrib = ProbabilityWeights(exp_T./sum_exp_T)
    sampled_idx = sample(s.rng, 1:length(legal_q_values), prob_distrib)
    return sampled_idx
end
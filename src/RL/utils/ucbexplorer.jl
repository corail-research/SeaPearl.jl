"""
    function (p::RL.UCBExplorer)(values::AbstractArray, mask)

By default, the UCBExplorer version of ReinforcementLearning.jl does not support masks. This function simply adds a mask.
"""
function (p::RL.UCBExplorer)(values::AbstractArray, mask)
    v, inds = RL.find_all_max((@. values + p.c * sqrt(log(p.step + 1) / p.actioncounts)), mask)
    a = @. values + p.c * sqrt(log(p.step + 1) / p.actioncounts)
    action = sample(p.rng, inds)
    if p.is_training
        p.actioncounts[action] += 1
        p.step += 1
    end
    action
end

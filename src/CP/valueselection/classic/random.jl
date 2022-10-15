"""
    select_random_value(x::SeaPearl.IntVar, rng::Union{Nothing,AbstractRNG})

Selects a random value of the domain of `x`.

A random generator `rng` can be specified, notably to ensure the reproducibility of results.
"""
function select_random_value(x::SeaPearl.IntVar, rng::Union{Nothing,AbstractRNG})
    if isnothing(rng)
        return rand(x.domain.values[1:x.domain.size.value]) + x.domain.offset
    else
        return rand(rng, x.domain.values[1:x.domain.size.value]) + x.domain.offset
    end
end

"""
    select_random_value(x::SeaPearl.BoolVar, rng::Union{Nothing,AbstractRNG})

Selects a random value of the domain of `x`.

A random generator `rng` can be specified, notably to ensure the reproducibility of results.
"""
function select_random_value(x::SeaPearl.BoolVar, rng::Union{Nothing,AbstractRNG})
    if isbound(x) # question: cette fonction
        return assignedValue(x)
    else
        if isnothing(rng)
            return rand(Bool)
        else
            return rand(rng, Bool)
        end
    end
end

"""
    RandomHeuristic(rng::Union{Nothing,AbstractRNG}=nothing)

Create a `BasicHeuristic` that selects a random value of the domain of a given variable.

A random generator `rng` can be specified, notably to ensure the reproducibility of results.
"""
RandomHeuristic(rng::Union{Nothing,AbstractRNG}=nothing) = BasicHeuristic((x; cpmodel = nothing) -> select_random_value(x, rng), nothing)

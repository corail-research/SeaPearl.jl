using DataStructures

abstract type StateEntry end


mutable struct Trailer
    current     ::Stack{StateEntry}
    prior       ::Stack{Stack{StateEntry}}
    Trailer() = new(Stack{StateEntry}(), Stack{Stack{StateEntry}}())
end

mutable struct StateInt
    value       ::Int
    trailer     ::Trailer
end

struct IntStateEntry <: StateEntry
    value       ::Int
    object      ::StateInt
end


"""
    trail!(var::StateInt)

Store the current value of `var` into its trailer.
"""
function trail!(var::StateInt)
    push!(var.trailer.current, IntStateEntry(var.value, var))
end


"""
    setValue!(var::StateInt, value::Int)

Change the value of `var`, replacing it with `value`, and if needed, stores the
former value into `var`'s trailer.
"""
function setValue!(var::StateInt, value::Int)
    if (value != var.value)
        trail!(var)
        var.value = value
    end
    return var.value
end

"""
    saveState!(trailer::Trailer)

Store the current state into the trailer, replacing the current stack with an empty one.
"""
function saveState!(trailer::Trailer)
    push!(trailer.prior, trailer.current)
    trailer.current = Stack{StateEntry}()
end

"""
    restoreState!(trailer::Trailer)

Iterate over the last state to restore every former value, used to backtrack every change made after the last call to [`saveState!`](@ref)
"""
function restoreState!(trailer::Trailer)
    for se in trailer.current
        se.object.value = se.value
    end

    if isempty(trailer.prior)
        trailer.current = Stack{StateEntry}()
    else
        trailer.current = pop!(trailer.prior)
    end
end


"""
    withNewState!(func, trailer::Trailer)

Call the `func` function with a new state, restoring it after. Aimed to be used with the `do` block syntax.

# Examples
```jldoctest
julia> using CPRL
julia> trailer = CPRL.Trailer()
julia> reversibleInt = CPRL.StateInt(3, trailer)
julia> CPRL.withNewState!(trailer) do
        CPRL.setValue!(reversibleInt, 5)
    end
julia> reversibleInt.value
3
```
"""
function withNewState!(func, trailer::Trailer)
    saveState!(trailer)
    func()
    restoreState!(trailer)
end

using DataStructures

"""
    abstract type AbstractStateEntry end

Any object that can be stacked into the trailer must be a subtype of this.
"""
abstract type AbstractStateEntry end

Base.show(io::IO, se::AbstractStateEntry) = write(io, "AbstractStateEntry")

"""
    Trailer

The trailer is the structure which makes it possible to memorize the previous State of our model 
during the search. It makes it possible to handle the backtrack.
"""
mutable struct Trailer
    current     ::Stack{AbstractStateEntry}
    prior       ::Stack{Stack{AbstractStateEntry}}
    Trailer() = new(Stack{AbstractStateEntry}(), Stack{Stack{AbstractStateEntry}}())
end


"""
    StateObject{T}(value::T, trailer::Trailer)

A reversible object of value `value` that has a type `T`, storing its modification into `trailer`.
"""
mutable struct StateObject{T}
    value       ::T
    trailer     ::Trailer
end

Base.show(io::IO, so::StateObject{T}) where {T} = write(io, "StateObject{", string(T), "}: ", string(so.value))


"""
    StateEntry{T}(value::T, object::StateObject{T})

An entry that can be stacked in the trailer, containing the former `value of the object, and a reference to
the `object` so that it can be restored by the trailer.
"""
struct StateEntry{T} <: AbstractStateEntry
    value       ::T
    object      ::StateObject{T}
end


"""
    trail!(var::StateObject{T})

Store the current value of `var` into its trailer.
"""
function trail!(var::StateObject)
    push!(var.trailer.current, StateEntry(var.value, var))
end

"""
    setValue!(var::StateObject{T}, value::T) where {T}

Change the value of `var`, replacing it with `value`, and if needed, store the
former value into `var`'s trailer.
"""
function setValue!(var::StateObject{T}, value::T) where {T}
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
    trailer.current = Stack{AbstractStateEntry}()
end

"""
    restoreState!(trailer::Trailer)

Iterate over the last state to restore every former value, used to backtrack every change 
made after the last call to [`saveState!`](@ref).
"""
function restoreState!(trailer::Trailer)
    for se in trailer.current
        se.object.value = se.value
    end

    if isempty(trailer.prior)
        trailer.current = Stack{AbstractStateEntry}()
    else
        trailer.current = pop!(trailer.prior)
    end
end


"""
    withNewState!(func, trailer::Trailer)

Call the `func` function with a new state, restoring it after. Aimed to be used with the `do` block syntax.

# Examples
```julia
using SeaPearl
trailer = SeaPearl.Trailer()
reversibleInt = SeaPearl.StateObject{Int}(3, trailer)
SeaPearl.withNewState!(trailer) do
    SeaPearl.setValue!(reversibleInt, 5)
end
reversibleInt.value # 3
```
"""
function withNewState!(func, trailer::Trailer)
    saveState!(trailer)
    func()
    restoreState!(trailer)
end

"""
    restoreInitialState!(trailer::Trailer)

Restore every linked object to its initial state. Basically call [`restoreState!`](@ref) until not possible.
"""
function restoreInitialState!(trailer::Trailer)
    while !isempty(trailer.prior)
        restoreState!(trailer)
    end
    restoreState!(trailer)
end

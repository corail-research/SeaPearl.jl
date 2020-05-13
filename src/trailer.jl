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

function trail!(var::StateInt)
    push!(var.trailer.current, IntStateEntry(var.value, var))
end

function setValue!(var::StateInt, value::Int)
    if (value != var.value)
        trail!(var)
        var.value = value
    end
    return var.value
end

function saveState!(trailer::Trailer)
    push!(trailer.prior, trailer.current)
    trailer.current = Stack{StateEntry}()
end

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

function withNewState!(func, trailer::Trailer)
    saveState!(trailer)
    func()
    restoreState!(trailer)
end

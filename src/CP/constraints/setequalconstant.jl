"""
    SetEqualConstant(s::IntSetVar, c::Set{Int}, trailer::Trailer)

SetEqualConstant constraint, states that s == c
"""
struct SetEqualConstant <: Constraint
    s       ::IntSetVar
    c       ::Set{Int}
    active  ::StateObject{Bool}
    function SetEqualConstant(s::IntSetVar, c::Set{Int}, trailer)
        constraint = new(s, c, StateObject{Bool}(true, trailer))
        addOnDomainChange!(s, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::SetEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`SetEqualConstant` propagation function.
"""
function propagate!(constraint::SetEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end

    # for every value in c, require in s
    for v in constraint.c
        if !is_possible(constraint.s.domain, v)
            return false
        elseif !is_required(constraint.s.domain, v)
            require!(constraint.s.domain, v)
            addToPrunedDomains!(prunedDomains, constraint.s, SetModification(;required=[v]))
        end
    end

    # for every required value in s, assert v in c
    for v in required_values(constraint.s.domain)
        if !(v in constraint.c)
            return false
        end
    end

    excluded = exclude_all!(constraint.s.domain)
    addToPrunedDomains!(prunedDomains, constraint.s, SetModification(;excluded=excluded))
    triggerDomainChange!(toPropagate, constraint.s)

    setValue!(constraint.active, false)

    if constraint in toPropagate
        pop!(toPropagate, constraint)
    end

    return true
end

variablesArray(constraint::SetEqualConstant) = [constraint.s]

function Base.show(io::IO, ::MIME"text/plain", con::SetEqualConstant)
    println(io, typeof(con), ": ", con.s.id, " == ", con.c, ", active = ", con.active)
    print(io, "   ", con.s)
end

function Base.show(io::IO, con::SetEqualConstant)
    print(io, typeof(con), ": ", con.s.id, " == ", con.c)
end

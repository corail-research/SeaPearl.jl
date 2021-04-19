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
    # Feasibility & requiring
    for v in constraint.c
        if !is_possible(constraint.s.domain, v)
            return false
        elseif !is_required(constraint.s.domain, v)
            require!(constraint.s.domain, v)
        end
    end

    exclude_all!(constraint.s.domain)

    triggerDomainChange!(toPropagate, constraint.s)

    setValue!(constraint.active, false)

    return true
end

variablesArray(constraint::SetEqualConstant) = [constraint.s]

function Base.show(io::IO, ::MIME"text/plain", con::SetEqualConstant)
    println(io, typeof(con), ": ", con.s.id, " == ", con.c, ", active = ", con.active)
    println(io, "   ", con.s)
end

function Base.show(io::IO, con::SetEqualConstant)
    print(io, typeof(con), ": ", con.s.id, " == ", con.c)
end

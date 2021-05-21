"""
    InSet(x::AbstractIntVar, s::IntSetVar, trailer::Trailer)

InSet constraint, states that x ∈ s
"""
struct InSet <: Constraint
    x       ::AbstractIntVar
    s       ::IntSetVar
    active  ::StateObject{Bool}
    function InSet(x::AbstractIntVar, s::IntSetVar, trailer)
        constraint = new(x, s, StateObject{Bool}(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(s, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::InSet, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`InSet` propagation function.
"""
function propagate!(constraint::InSet, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    # Feasibility

    if all(!is_possible(constraint.s.domain, v) for v in constraint.x.domain)
        return false
    end

    # Filter x
    x_values = collect(constraint.x.domain)
    for v in x_values
        if !is_possible(constraint.s.domain, v)
            remove!(constraint.x.domain, v)
            addToPrunedDomains!(prunedDomains, constraint.x, [v])
            triggerDomainChange!(toPropagate, constraint.x)
        end
    end

    # Filter s
    if isbound(constraint.x)
        if !is_required(constraint.s.domain, assignedValue(constraint.x))
            require!(constraint.s.domain, assignedValue(constraint.x))
            # TODO log modifications on s
            triggerDomainChange!(toPropagate, constraint.s)
        end
    end


    # Deactivation
    if all(is_required(constraint.s.domain, v) for v in constraint.x.domain)
        setValue!(constraint.active, false)
    end

    return true
end

variablesArray(constraint::InSet) = [constraint.x, constraint.s]

function Base.show(io::IO, ::MIME"text/plain", con::InSet)
    println(io, typeof(con), ": ", con.x.id, " ∈ ", con.s.id, ", active = ", con.active)
    println(io, "   ", con.x)
    print(io, "   ", con.s)
end

function Base.show(io::IO, con::InSet)
    print(io, typeof(con), ": ", con.x.id, " ∈ ", con.s.id)
end

"""
    ReifiedInSet(x::AbstractIntVar, s::IntSetVar, b::BoolVar, trailer::Trailer)

ReifiedInSet contrainst, states that b ⟺ x ∈ s
"""
struct ReifiedInSet <: Constraint
    x       ::AbstractIntVar
    s       ::IntSetVar
    b       ::AbstractBoolVar
    active  ::StateObject{Bool}
    function ReifiedInSet(x::AbstractIntVar, s::IntSetVar, b::AbstractBoolVar, trailer::Trailer)
        constraint = new(x, s, b, StateObject{Bool}(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(s, constraint)
        addOnDomainChange!(b, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::ReifiedInSet, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`ReifiedInSet` propagation function.
"""
function propagate!(constraint::ReifiedInSet, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    surely_in_set = all(is_required(constraint.s.domain, v) for v in constraint.x.domain)
    surely_notin_set = all(!is_possible(constraint.s.domain, v) for v in constraint.x.domain)


    if isbound(constraint.b)
        # Feasibility
        if assignedValue(constraint.b) && surely_notin_set
            return false
        end
        if !assignedValue(constraint.b) && surely_in_set
            return false
        end

        # Filtering s & x
        if assignedValue(constraint.b) # Make sure x ∈ s
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
                    # TODO log modifications in s
                    triggerDomainChange!(toPropagate, constraint.s)
                end
            end
        else # Make sure x ∉ s
            # Filter x
            x_values = collect(constraint.x.domain)
            for v in x_values
                if is_required(constraint.s.domain, v)
                    remove!(constraint.x.domain, v)
                    addToPrunedDomains!(prunedDomains, constraint.x, [v])
                    triggerDomainChange!(toPropagate, constraint.x)
                end
            end

            # Filter s
            if isbound(constraint.x)
                if is_possible(constraint.s.domain, assignedValue(constraint.x))
                    exclude!(constraint.s.domain, assignedValue(constraint.x))
                    # TODO log modifications in s
                    triggerDomainChange!(toPropagate, constraint.s)
                end
            end
        end
    else
        # No feasibility test because if b not assigned, it is always feasible

        # Filtering b
        if surely_in_set
            removed = assign!(constraint.b, true)
            addToPrunedDomains!(prunedDomains, constraint.b, removed)
            triggerDomainChange!(toPropagate, constraint.b)
        end
        if surely_notin_set
            removed = assign!(constraint.b, false)
            addToPrunedDomains!(prunedDomains, constraint.b, removed)
            triggerDomainChange!(toPropagate, constraint.b)
        end
    end

    surely_in_set = all(is_required(constraint.s.domain, v) for v in constraint.x.domain)
    surely_notin_set = all(!is_possible(constraint.s.domain, v) for v in constraint.x.domain)

    # Deactivation
    if isbound(constraint.b) && ((assignedValue(constraint.b) && surely_in_set) || (!assignedValue(constraint.b) && surely_notin_set))
        setValue!(constraint.active, false)
    end

    return true
end

variablesArray(constraint::ReifiedInSet) = [constraint.x, constraint.s, constraint.b]

function Base.show(io::IO, ::MIME"text/plain", con::ReifiedInSet)
    println(io, typeof(con), ": ", con.b.id, " ≡ ", con.x.id, " ∈ ", con.s.id, ", active = ", con.active)
    println(io, "   ", con.b)
    println(io, "   ", con.x)
    print(io, "   ", con.s)
end

function Base.show(io::IO, con::ReifiedInSet)
    print(io, typeof(con), ": ", con.b.id, " ≡ ", con.x.id, " ∈ ", con.s.id)
end

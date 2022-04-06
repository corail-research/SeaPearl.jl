"""
    BinaryXor(x::AbstractBoolVar, y::AbstractBoolVar)

Binary Xor constraint, states that `x ⊕ y`.
"""
struct BinaryXor <: Constraint
    x::AbstractBoolVar
    y::AbstractBoolVar
    active::StateObject{Bool}

    function BinaryXor(x::AbstractBoolVar, y::AbstractBoolVar, trailer)
        constraint = new(x, y, StateObject{Bool}(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::BinaryOr, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`BinaryXor` propagation function.
"""
function propagate!(constraint::BinaryXor, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if isbound(constraint.x)
        if assignedValue(constraint.x) # x = true => y = false
            prunedY = remove!(constraint.y.domain, true)
            if !isempty(prunedY)
                addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
                triggerDomainChange!(toPropagate, constraint.y)
            end
            setValue!(constraint.active, false)
            return !isempty(constraint.y.domain)
        else # x = false => y = true
            prunedY = remove!(constraint.y.domain, false)
            if !isempty(prunedY)
                addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
                triggerDomainChange!(toPropagate, constraint.y)
            end
            setValue!(constraint.active, false)
            return !isempty(constraint.y.domain)
        end
    elseif isbound(constraint.y)
        if assignedValue(constraint.y) # y = true => x = false
            prunedX = remove!(constraint.x.domain, true)
            if !isempty(prunedX)
                addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
                triggerDomainChange!(toPropagate, constraint.x)
            end
            setValue!(constraint.active, false)
            return !isempty(constraint.x.domain)
        else # y = false => x = true
            prunedX = remove!(constraint.x.domain, false)
            if !isempty(prunedX)
                addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
                triggerDomainChange!(toPropagate, constraint.x)
            end
            setValue!(constraint.active, false)
            return !isempty(constraint.x.domain)
        end
    end

    return true
end

variablesArray(constraint::BinaryXor) = [constraint.x, constraint.y]

function Base.show(io::IO, ::MIME"text/plain", con::BinaryXor)
    println(io, string(typeof(con)), ": ", con.x.id, " ⊕ ", con.y.id, ", active = ", con.active)
    println(io, "   ", con.x)
    print(io, "   ", con.y)
end

function Base.show(io::IO, con::BinaryXor)
    print(io, typeof(con), ": ", con.x.id, " ⊕ ", con.y.id)
end

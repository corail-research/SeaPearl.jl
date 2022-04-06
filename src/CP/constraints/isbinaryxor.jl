"""
    isBinaryXor(b::AbstractBoolVar, x::AbstractBoolVar, y::AbstractBoolVar)

Is Xor constraint, states that `b <=> x ⊻ y`.
"""
struct isBinaryXor <: Constraint
    b::AbstractBoolVar
    x::AbstractBoolVar
    y::AbstractBoolVar
    active::StateObject{Bool}

    function isBinaryXor(b::AbstractBoolVar, x::AbstractBoolVar, y::AbstractBoolVar, trailer)
        constraint = new(b, x, y, StateObject{Bool}(true, trailer))
        addOnDomainChange!(b, constraint)
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::isBinaryXor, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`isBinaryXor` propagation function.
"""
function propagate!(constraint::isBinaryXor, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if isbound(constraint.b)
        if !assignedValue(constraint.b) # b is false
            if isbound(constraint.x)
                if assignedValue(constraint.x) # x = true => y = true
                    prunedY = remove!(constraint.y.domain, false)
                    if !isempty(prunedY)
                        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
                        triggerDomainChange!(toPropagate, constraint.y)
                    end
                    setValue!(constraint.active, false)
                    return !isempty(constraint.y.domain)
                else # x = false => y = false
                    prunedY = remove!(constraint.y.domain, true)
                    if !isempty(prunedY)
                        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
                        triggerDomainChange!(toPropagate, constraint.y)
                    end
                    setValue!(constraint.active, false)
                    return !isempty(constraint.y.domain)
                end
            elseif isbound(constraint.y)
                if assignedValue(constraint.y) # y = true => x = true
                    prunedX = remove!(constraint.x.domain, false)
                    if !isempty(prunedX)
                        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
                        triggerDomainChange!(toPropagate, constraint.x)
                    end
                    setValue!(constraint.active, false)
                    return !isempty(constraint.x.domain)
                else # y = false => x = false
                    prunedX = remove!(constraint.x.domain, true)
                    if !isempty(prunedX)
                        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
                        triggerDomainChange!(toPropagate, constraint.x)
                    end
                    setValue!(constraint.active, false)
                    return !isempty(constraint.x.domain)
                end
            end
        else # b is true
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
        end
    else # b is not bound
        if isbound(constraint.x) && isbound(constraint.y)
            if assignedValue(constraint.x) != assignedValue(constraint.y) # x = y
                prunedB = remove!(constraint.b.domain, false)
                addToPrunedDomains!(prunedDomains, constraint.b, prunedB)
                triggerDomainChange!(toPropagate, constraint.b)
                setValue!(constraint.active, false)
            else # x ≠ y
                prunedB = remove!(constraint.b.domain, true)
                addToPrunedDomains!(prunedDomains, constraint.b, prunedB)
                triggerDomainChange!(toPropagate, constraint.b)
                setValue!(constraint.active, false)
            end
        end
    end

    return true
end

variablesArray(constraint::isBinaryXor) = [constraint.b, constraint.x, constraint.y]

function Base.show(io::IO, ::MIME"text/plain", con::isBinaryXor)
    println(io, typeof(con), ": ", con.b.id, " ≡ ", con.x.id, " ⊻ ", con.y.id, ", active = ", con.active)
    print(io, "   ", con.x)
end

function Base.show(io::IO, con::isBinaryXor)
    print(io, typeof(con), ": ", con.b.id, " ≡ ", con.x.id, " ⊻ ", con.y.id)
end

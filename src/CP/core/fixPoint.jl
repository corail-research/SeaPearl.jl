"""
    fixPoint!(model::CPModel, new_constraints=nothing)

Run the fix-point algorithm. Will prune the domain of every variable of `model` as much as possible, using its constraints.
Return a tuple with a boolean corresponding to the feasibility and a `CPModification` object, containing all the pruned domains.

# Arguments
- `model::CPModel`: the model you want to apply the algorithm on.
- `new_constraints::Union{Array{Constraint}, Nothing}`: if this is filled with a set of constraints, 
only those will be propagated in the first place.
"""
function fixPoint!(model::CPModel, new_constraints::Union{Array{Constraint}, Nothing}=nothing, prunedDomains::Union{CPModification,Nothing}=nothing)
    toPropagate = Set{Constraint}()

    if isnothing(prunedDomains)
        prunedDomains = CPModification()
    end

    # If we did not specify the second argument, it is the beginning so we propagate every constraint
    if isnothing(new_constraints)
        addToPropagate!(toPropagate, model.constraints)
    else
        addToPropagate!(toPropagate, new_constraints)
    end

    # Dealing with the objective
    if !isnothing(model.objectiveBound)
        prunedObj = removeAbove!(model.objective.domain, model.objectiveBound)
        if isempty(model.objective.domain)
            return false, prunedDomains
        end

        if !isempty(prunedObj)
            addToPrunedDomains!(prunedDomains, model.objective, prunedObj)
            triggerDomainChange!(toPropagate, model.objective)
        end
    end

    while !isempty(toPropagate)
        constraint = pop!(toPropagate)
        if !propagate!(constraint, toPropagate, prunedDomains)
            triggerInfeasible!(constraint, model)   
            return false, prunedDomains
        end
    end

    return true, prunedDomains
end
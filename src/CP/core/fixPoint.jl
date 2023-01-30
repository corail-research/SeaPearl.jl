"""
    fixPoint!(model::CPModel, new_constraints=nothing)

Run the fix-point algorithm. Will prune the domain of every variable of `model` as much as possible, using its constraints.
Return a tuple with a boolean corresponding to the feasibility and a `CPModification` object, containing all the pruned domains.

# Arguments
- `model::CPModel`: the model you want to apply the algorithm on.
- `new_constraints::Union{Array{Constraint}, Nothing}`: if this is filled with a set of constraints, 
only those will be propagated in the first place.
"""
function fixPoint!(model::CPModel, new_constraints::Union{Array{Constraint}, Nothing}=nothing, prunedDomains::Union{CPModification,Nothing}=nothing; isFailureBased::Bool=false)
    toPropagate = Set{Constraint}()
    if isnothing(prunedDomains)
        prunedDomains = CPModification()
    end

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
        if haskey(model.statistics.numberOfTimesInvolvedInPropagation,constraint)
            model.statistics.numberOfTimesInvolvedInPropagation[constraint] += 1
        end
        if !propagate!(constraint, toPropagate, prunedDomains)
            triggerInfeasible!(constraint, model; isFailureBased=isFailureBased)   
            return false, prunedDomains
        end
    end

    #impact value computation :
    if isnothing(model.statistics.searchTreeSize)
        model.statistics.searchTreeSize = SeaPearl.computeSearchTreeSize!(model)
    elseif !isnothing(model.statistics.lastVar) #if this is not the first fix-point
        x = model.statistics.lastVar
        v = model.statistics.lastVal
        alpha = 0.4
        impact = 1 - SeaPearl.computeSearchTreeSize!(model)/model.statistics.searchTreeSize  #after/before fix point
        model.statistics.searchTreeSize = SeaPearl.computeSearchTreeSize!(model) #updating searchTreeSize
        if !isnothing(get(model.impact_var_val, (x,v), nothing)) #tuple (x,v) previously seen
            model.impact_var_val[(x,v)] = (1-alpha)*model.impact_var_val[(x,v)] + alpha * impact
        else
            model.impact_var_val[(x,v)] = impact
        end
        activity = 0
        #activity value computation : 
        for var in model.branchable_variables
            if isdefined(var, :is_impacted) && var.is_impacted
                activity+=1
                var.is_impacted = false
            end
        end
        if !isnothing(get(model.activity_var_val, (x,v), nothing)) #tuple (x,v) previously seen
            model.activity_var_val[(x,v)] = (1-alpha)*model.activity_var_val[(x,v)] + alpha * activity
        else
            model.activity_var_val[(x,v)] = activity
        end
    
    end

    return true, prunedDomains
end
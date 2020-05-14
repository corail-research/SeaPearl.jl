"""
    fixPoint!(model::CPModel, new_constraints=nothing)

Run the fix-point algorithm. Will prune the domain of every variable of `model` as much
as possible, using its constraints.

# Arguments
- `model::CPModel`: the model you want to apply the algorithm on.
- `new_constraints::Union{Array{Constraint}, Nothing}`: if this is filled with a set of constraints, 
only those will be propagated in the first place.
"""
function fixPoint!(model::CPModel, new_constraints=nothing)
    toPropagate = Set{Constraint}()

    # If we did not specify the second argument, it is the beginning so we propagate every constraint
    if isnothing(new_constraints)
        for constraint in model.constraints
            if constraint.active
                push!(toPropagate, constraint)
            end
        end
    else
        union!(toPropagate, new_constraints)
    end

    while !isempty(toPropagate)
        constraint = pop!(toPropagate)
        propagate!(constraint, toPropagate)
    end
end
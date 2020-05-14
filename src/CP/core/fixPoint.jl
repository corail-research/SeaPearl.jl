function fixPoint!(model::CPModel)
    toPropagate = Set{Constraint}()

    for constraint in model.constraints
        if constraint.active
            push!(toPropagate, constraint)
        end
    end

    while !isempty(toPropagate)
        constraint = pop!(toPropagate)
        propagate!(constraint, toPropagate)
    end
end
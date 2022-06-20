
struct RandomVariableSelection{TakeObjective} <: AbstractVariableSelection{TakeObjective} end

RandomVariableSelection(;take_objective=true) = RandomVariableSelection{take_objective}()

function (::RandomVariableSelection{true})(cpmodel::CPModel; rng=nothing)
    var_ids = keys(branchable_variables(cpmodel))
    acceptable_ids = String[]
    for id in var_ids
        x = cpmodel.variables[id]
        if !isbound(x) && x !== cpmodel.objective
            push!(acceptable_ids, id)
        end
    end

    if isempty(acceptable_ids)
        return cpmodel.objective
    end

    if !isnothing(rng)
        return cpmodel.variables[acceptable_ids[rand(rng, 1:length(acceptable_ids))]]
    end
    cpmodel.variables[acceptable_ids[rand(1:length(acceptable_ids))]]
end

function (::RandomVariableSelection{false})(cpmodel::CPModel; rng=nothing)
    var_ids = keys(branchable_variables(cpmodel))
    acceptable_ids = String[]
    for id in var_ids
        x = cpmodel.variables[id]
        if !isbound(x)
            push!(acceptable_ids, id)
        end
    end
    if !isnothing(rng)
        return cpmodel.variables[acceptable_ids[rand(rng, 1:length(acceptable_ids))]]
    end
    cpmodel.variables[acceptable_ids[rand(1:length(acceptable_ids))]]
end

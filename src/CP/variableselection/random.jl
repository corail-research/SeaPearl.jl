struct RandomVariableSelection{TakeObjective} end

RandomVariableSelection(;take_objective=true) = RandomVariableSelection{take_objective}()

function (::RandomVariableSelection{false})(cpmodel::CPModel; rng=Base.Random.RANDOM_SEED)
    var_ids = keys(cpmodel.variables)
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

    cpmodel.variables[acceptable_ids[rand(rng, 1:length(acceptable_ids))]]
end

function (::RandomVariableSelection{true})(cpmodel::CPModel; rng=Base.Random.RANDOM_SEED)
    var_ids = keys(cpmodel.variables)
    acceptable_ids = String[]
    for id in var_ids
        x = cpmodel.variables[id]
        if !isbound(x)
            push!(acceptable_ids, id)
        end
    end
    
    cpmodel.variables[acceptable_ids[rand(rng, 1:length(acceptable_ids))]]
end

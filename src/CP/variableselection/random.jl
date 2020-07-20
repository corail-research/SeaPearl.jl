struct RandomVariableSelection{TakeObjective} end

function (::MinDomainVariableSelection{false})(cpmodel::CPModel)
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

    cpmodel.variables[acceptable_ids[rand(1:length(acceptable_ids))]]
end

function (::MinDomainVariableSelection{true})(cpmodel::CPModel)
    var_ids = keys(cpmodel.variables)
    acceptable_ids = String[]
    for id in var_ids
        x = cpmodel.variables[id]
        if !isbound(x)
            push!(acceptable_ids, id)
        end
    end
    
    cpmodel.variables[acceptable_ids[rand(1:length(acceptable_ids))]]
end

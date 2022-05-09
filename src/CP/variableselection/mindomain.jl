struct MinDomainVariableSelection{TakeObjective} <: AbstractVariableSelection{TakeObjective} end

MinDomainVariableSelection(;take_objective=true) = MinDomainVariableSelection{take_objective}()

function (::MinDomainVariableSelection{false})(cpmodel::CPModel)
    selectedVar = nothing
    minSize = typemax(Int)
    for (k, x) in cpmodel.branchable_variables
        if x !== cpmodel.objective && !isbound(x) && length(x.domain) < minSize
            selectedVar = x
            minSize = length(x.domain)
        end
    end
    if isnothing(selectedVar) && !isbound(cpmodel.objective)
        return cpmodel.objective
    end
    return selectedVar
end

function (::MinDomainVariableSelection{true})(cpmodel::CPModel)
    selectedVar = nothing
    minSize = typemax(Int)
    for (k, x) in cpmodel.branchable_variables
        if !isbound(x) && length(x.domain) < minSize
            selectedVar = x
            minSize = length(x.domain)
        end
    end
    return selectedVar
end

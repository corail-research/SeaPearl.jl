struct FailureBasedVariableSelection{TakeObjective} <: AbstractVariableSelection{TakeObjective} end

FailureBasedVariableSelection(;take_objective=true) = FailureBasedVariableSelection{take_objective}()

function (::FailureBasedVariableSelection{false})(cpmodel::CPModel)
    selectedVar = nothing
    minSize = Inf
    for (k, x) in branchable_variables(cpmodel)
        if x !== cpmodel.objective && !isbound(x) && length(x.domain) / cpmodel.statistics.infeasibleStatusPerVariable[parentId(x)] <= minSize
            selectedVar = x
            minSize = length(x.domain) / cpmodel.statistics.infeasibleStatusPerVariable[parentId(x)]
        end
    end
    if isnothing(selectedVar) && !isbound(cpmodel.objective)
        return cpmodel.objective
    end
    return selectedVar
end

function (::FailureBasedVariableSelection{true})(cpmodel::CPModel)
    selectedVar = nothing
    minSize = Inf
    for (k, x) in branchable_variables(cpmodel)
        if !isbound(x) && length(x.domain)/ cpmodel.statistics.infeasibleStatusPerVariable[parentId(x)] <= minSize
            selectedVar = x
            minSize = length(x.domain) / cpmodel.statistics.infeasibleStatusPerVariable[parentId(x)]
        end
    end
    return selectedVar
end

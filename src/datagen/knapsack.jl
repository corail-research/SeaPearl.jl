using Distributions

"""
    fill_with_knapsack!(cpmodels::Array{CPModel}, nb_items, noise)::CPModel    

Fill the cpmodels with the same variables and constraints generated. We fill them directly instead of 
creating temporary files for efficiency purpose! Density should be more than 1.
"""
function fill_with_knapsack!(cpmodels::Array{CPModel}, nb_items::Int64, noise::Number=1)
    
    # create values, weights and capacity
    distr = Truncated(Normal(5 * nb_items, nb_items), 1, 10 * nb_items)
    perturbation = Truncated(Normal(0, noise), -10, 10)

    values = rand(distr, nb_items)
    weights = (1 + perturbation) .* values
    capacity = (0.5 + 0.25 * rand()) * sum(weights)
    
    for cpmodel in cpmodels
        ### Variables
        x = CPRL.IntVar[]
        for i in 1:nb_items
            push!(x, CPRL.IntVar(0, 1, "x[" * string(i) * "]", cpmodel.trailer))
            addVariable!(cpmodel, last(x))
        end

        ### Constraints

        # Creating the totalWeight variable
        varsWeight = CPRL.AbstractIntVar[]
        maxWeight = 0
        for i in 1:nb_items
            wx_i = CPRL.IntVarViewMul(x[i], weights[i], "w["*string(i)*"]*x["*string(i)*"]")
            push!(varsWeight, wx_i)
            maxWeight += weights[i]
        end
        totalWeight = CPRL.IntVar(0, maxWeight, "totalWeight", cpmodel.trailer)
        minusTotalWeight = CPRL.IntVarViewOpposite(totalWeight, "-totalWeight")
        CPRL.addVariable!(cpmodel, totalWeight)
        CPRL.addVariable!(cpmodel, minusTotalWeight)
        push!(varsWeight, minusTotalWeight)
        weightEquality = CPRL.SumToZero(varsWeight, cpmodel.trailer)
        push!(cpmodel.constraints, weightEquality)

        # Making sure it is below the capacity
        weightConstraint = CPRL.LessOrEqualConstant(totalWeight, capacity, cpmodel.trailer)
        push!(cpmodel.constraints, weightConstraint)

        ### Objective ### minimize: -sum(v[i]*x_a[i])

        # Creating the sum
        varsValue = CPRL.AbstractIntVar[]
        maxValue = 0
        for i in 1:nb_items
            vx_i = CPRL.IntVarViewMul(x[i], values[i], "v["*string(i)*"]*x["*string(i)*"]")
            push!(varsValue, vx_i)
            maxValue += values[i]
        end
        totalValue = CPRL.IntVar(-maxValue, 0, "totalValue", cpmodel.trailer)
        CPRL.addVariable!(cpmodel, totalValue)
        push!(varsValue, totalValue)
        valueEquality = CPRL.SumToZero(varsValue, cpmodel.trailer)
        push!(cpmodel.constraints, valueEquality)

        # Setting it as the objective
        cpmodel.objective = totalValue
    end

    nothing
end
fill_with_knapsack!(cpmodel::CPModel, nb_items::Int64, noise::Number=1) = fill_with_knapsack!(CPModel[cpmodel], nb_items, noise)
using Distributions

"""
    fill_with_knapsack!(cpmodels::Array{CPModel}, nb_items, max_weight, correlation=1)::CPModel    

Fill the cpmodels with the same variables and constraints for knapsack problem.
The weights are uniformly distributed between 1 and `max_weight`, the values are uniformly distributed
between (for each `weight`) `weight - max_weight/(10*correlation)` and `weight + max_weight/(10*correlation)`.
It is possible to give `Inf` as the `correlation` to have a strict equality between the weights and their values.
`correlation` must be strictly positive.

This method is from the following paper:
https://www.researchgate.net/publication/2548374_Core_Problems_in_Knapsack_Algorithms
"""
function fill_with_knapsack!(cpmodels::Array{CPModel}, nb_items::Int64, max_weight::Int, correlation::Real=1)
    @assert correlation > 0
    
    # create values, weights and capacity
    weights_distr = DiscreteUniform(1, max_weight)
    weights = rand(weights_distr, nb_items)

    value_distr = Truncated.(DiscreteUniform.(weights .- max_weight/(10*correlation), weights .+ max_weight/(10*correlation)), 1, Inf)
    values = rand.(value_distr)

    c = floor(nb_items * max_weight/2 / 4)
    capacity = rand(DiscreteUniform(c, c*4))
    
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
fill_with_knapsack!(cpmodel::CPModel, nb_items::Int64, max_weight::Int, correlation::Real) = fill_with_knapsack!(CPModel[cpmodel], nb_items, max_weight, correlation)
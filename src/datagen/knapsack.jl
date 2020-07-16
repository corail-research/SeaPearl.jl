using Distributions

struct KnapsackGenerator <: AbstractModelGenerator
    nb_items::Int
    max_weight::Int
    correlation::Real
end

KnapsackGenerator(nb_items::Int, max_weight::Int) = KnapsackGenerator(nb_items, max_weight, 1)

"""
    fill_with_generator!(cpmodel::CPModel, gen::KnapsackGenerator)::CPModel
 
Fill the cpmodel with variables and constraints for the knapsack problem.
The weights are uniformly distributed between 1 and `gen.max_weight`, the values are uniformly distributed
between (for each `weight`) `weight - max_weight/(10*correlation)` and `weight + max_weight/(10*correlation)`.
It is possible to give `Inf` as the `gen.correlation` to have a strict equality between the weights and their values.
`gen.correlation` must be strictly positive.
This method is from the following paper:
https://www.researchgate.net/publication/2548374_Core_Problems_in_Knapsack_Algorithms
"""
function fill_with_generator!(cpmodel::CPModel, gen::KnapsackGenerator)
    correlation = gen.correlation
    max_weight = gen.max_weight
    nb_items = gen.nb_items


    @assert correlation > 0
    
    # create values, weights and capacity
    weights_distr = DiscreteUniform(1, max_weight)
    weights = rand(weights_distr, nb_items)

    deviation = floor(max_weight/(10*correlation))
    value_distr = truncated.(DiscreteUniform.(weights .- deviation, weights .+ deviation), 1, Inf)
    values = rand.(value_distr)

    c = floor(nb_items * max_weight/2 / 4)
    capacity = rand(DiscreteUniform(c, c*4))
    
    
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
    

    nothing
end
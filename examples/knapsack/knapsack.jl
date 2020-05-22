using CPRL

struct Item
    id      :: Int
    value   :: Int
    weight  :: Int
end

mutable struct Solution
    content     :: AbstractArray{Bool}
    value       :: Int
    weight      :: Int
    optimality  :: Bool
end

struct InputData
    items               :: AbstractArray{Union{Item, Nothing}}
    sortedItems         :: AbstractArray{Union{Item, Nothing}}
    numberOfItems       :: Int
    capacity            :: Int
end

include("IOmanager.jl")


function solve_knapsack(filename::String; benchmark=false)
    
    input = parseFile!(filename)

    permutation = sortperm(input.items; by=(x) -> x.value/x.weight, rev=true)

    n = input.numberOfItems

    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)

    ### Variable declaration ###
    x_s = CPRL.IntVar[]
    x_a = CPRL.IntVar[]
    for i in 1:n
        push!(x_s, CPRL.IntVar(0, input.capacity, "x_s[" * string(i) * "]", trailer))
        push!(x_a, CPRL.IntVar(0, 1, "x_a[" * string(i) * "]", trailer))
        CPRL.addVariable!(model, last(x_s))
        CPRL.addVariable!(model, last(x_a))
    end

    push!(x_s, CPRL.IntVar(0, input.capacity, "x_s[" * string(n+1) * "]", trailer))
    CPRL.addVariable!(model, last(x_s))


    ### Constraints ###
    # Initial state: x_s[1] = 0
    initial = CPRL.EqualConstant(x_s[1], 0, trailer)
    push!(model.constraints, initial)

    # Transition: x_s[i+1] = x_s[i] + w[i]*x_a[i]
    for i in 1:n
        w_x_a_i = CPRL.IntVarViewMul(x_a[i], input.items[permutation[i]].weight, "w["*string(i)*"]*x_a["*string(i)*"]")
        minusX_s = CPRL.IntVarViewOpposite(x_s[i+1], "-x_s["*string(i+1)*"]")
        CPRL.addVariable!(model, w_x_a_i)
        CPRL.addVariable!(model, minusX_s)
        vars = CPRL.AbstractIntVar[w_x_a_i, minusX_s, x_s[i]]
        transition = CPRL.SumToZero(vars, trailer)
        push!(model.constraints, transition)
    end

    ### Objective ### minimize: -sum(v[i]*x_a[i])
    vars = CPRL.AbstractIntVar[]
    maxValue = 0
    for i in 1:n
        vx_a_i = CPRL.IntVarViewMul(x_a[i], input.items[permutation[i]].value, "v["*string(i)*"]*x_a["*string(i)*"]")
        push!(vars, vx_a_i)
        maxValue += input.items[permutation[i]].value
    end
    y = CPRL.IntVar(-maxValue, 0, "y", trailer)
    CPRL.addVariable!(model, y)
    push!(vars, y)
    objective = CPRL.SumToZero(vars, trailer)
    push!(model.constraints, objective)
    model.objective = y



    status = CPRL.solve!(model; variableHeuristic=selectVariable)

    if !benchmark
        print(status)
        for oneSolution in model.solutions
            output = solutionFromCPRL(oneSolution, input, permutation)
            printSolution(output)
        end
    end
    return status
end

function solve_knapsack_without_dp(filename::String; benchmark=false)
    input = parseFile!(filename)

    permutation = sortperm(input.items; by=(x) -> x.value/x.weight, rev=true)

    n = input.numberOfItems

    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)

    ### Variable declaration ###
    x = CPRL.IntVar[]
    for i in 1:n
        push!(x, CPRL.IntVar(0, 1, "x[" * string(i) * "]", trailer))
        CPRL.addVariable!(model, last(x))
    end


    ### Constraints ###

    # Creating the totalWeight variable
    varsWeight = CPRL.AbstractIntVar[]
    maxWeight = 0
    for i in 1:n
        wx_i = CPRL.IntVarViewMul(x[i], input.items[permutation[i]].weight, "w["*string(i)*"]*x["*string(i)*"]")
        push!(varsWeight, wx_i)
        maxWeight += input.items[permutation[i]].weight
    end
    totalWeight = CPRL.IntVar(0, maxWeight, "totalWeight", trailer)
    minusTotalWeight = CPRL.IntVarViewOpposite(totalWeight, "-totalWeight")
    CPRL.addVariable!(model, totalWeight)
    CPRL.addVariable!(model, minusTotalWeight)
    push!(varsWeight, minusTotalWeight)
    weightEquality = CPRL.SumToZero(varsWeight, trailer)
    push!(model.constraints, weightEquality)

    # Making sure it is below the capacity
    weightConstraint = CPRL.LessOrEqualConstant(totalWeight, input.capacity, trailer)
    push!(model.constraints, weightConstraint)



    ### Objective ### minimize: -sum(v[i]*x_a[i])

    # Creating the sum
    varsValue = CPRL.AbstractIntVar[]
    maxValue = 0
    for i in 1:n
        vx_i = CPRL.IntVarViewMul(x[i], input.items[permutation[i]].value, "v["*string(i)*"]*x["*string(i)*"]")
        push!(varsValue, vx_i)
        maxValue += input.items[permutation[i]].value
    end
    totalValue = CPRL.IntVar(-maxValue, 0, "totalValue", trailer)
    CPRL.addVariable!(model, totalValue)
    push!(varsValue, totalValue)
    valueEquality = CPRL.SumToZero(varsValue, trailer)
    push!(model.constraints, valueEquality)

    # Setting it as the objective
    model.objective = totalValue



    status = CPRL.solve!(model; variableHeuristic=selectVariableWithoutDP)

    if !benchmark
        print(status)
        for oneSolution in model.solutions
            output = solutionFromCPRLWithoutDP(oneSolution, input, permutation)
            printSolution(output)
        end
    end
    return status
end

function selectVariable(model::CPRL.CPModel)
    i = 1
    while CPRL.isbound(model.variables["x_a[" * string(i) * "]"])
        i += 1
    end
    return model.variables["x_a[" * string(i) * "]"]
end

function selectVariableWithoutDP(model::CPRL.CPModel)
    i = 1
    while CPRL.isbound(model.variables["x[" * string(i) * "]"])
        i += 1
    end
    return model.variables["x[" * string(i) * "]"]
end

function solutionFromCPRL(cprlSol::CPRL.Solution, input::InputData, permutation::Array{Int})
    taken = falses(input.numberOfItems)
    value = 0
    weight = 0
    for i in 1:input.numberOfItems
        if haskey(cprlSol, "x_a[" * string(i) * "]")
            taken[permutation[i]] = convert(Bool, cprlSol["x_a[" * string(i) * "]"])
            if taken[permutation[i]]
                value += input.items[permutation[i]].value
                weight += input.items[permutation[i]].weight
            end
        end
    end
    return Solution(taken, value, weight, false)
end


function solutionFromCPRLWithoutDP(cprlSol::CPRL.Solution, input::InputData, permutation::Array{Int})
    taken = falses(input.numberOfItems)
    value = 0
    weight = 0
    for i in 1:input.numberOfItems
        if haskey(cprlSol, "x[" * string(i) * "]")
            taken[permutation[i]] = convert(Bool, cprlSol["x[" * string(i) * "]"])
            if taken[permutation[i]]
                value += input.items[permutation[i]].value
                weight += input.items[permutation[i]].weight
            end
        end
    end
    return Solution(taken, value, weight, false)
end

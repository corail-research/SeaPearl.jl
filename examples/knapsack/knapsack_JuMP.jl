using JuMP
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


function solve_knapsack_JuMP(filename::String; benchmark=false)
    input = parseFile!(filename)

    permutation = sortperm(input.items; by=(x) -> x.value/x.weight, rev=true)

    n = input.numberOfItems

    model = Model(CPRL.Optimizer)

    ### Variable declaration ###
    @variable(model, 0 <= x[1:n] <= 1)


    ### Constraints ###
    @expression(model, weight_sum, input.items[permutation[1]].weight * x[1])
    for i in 2:n
        add_to_expression!(weight_sum, input.items[permutation[i]].weight, x[i])
    end
    @constraint(model, weight_sum <= input.capacity)



    ### Objective ### minimize: -sum(v[i]*x_a[i])
    var_sum = @expression(model, 0)
    for i in 1:n
        add_to_expression!(weight_sum, input.items[permutation[i]].value, x[i])
    end
    @objective(model, Max, var_sum)


    variableheuristic(m) = selectVariableWithoutDP(m)

    MOI.set(model, CPRL.VariableSelection(), variableheuristic)

    optimize!(model)
    status = MOI.get(model, MOI.TerminationStatus())

    println(model)
    println(status)
    println(has_values(model))
    println(value.(x))
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

using DataStructures
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


function solve_knapsack(filename::String; benchmark=false, exact=true)
    
    input = parseFile!(filename)

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
        w_x_a_i = CPRL.IntVarViewMul(x_a[i], input.items[i].weight, "w["*string(i)*"]*x_a["*string(i)*"]")
        minusX_s = CPRL.IntVarViewOpposite(x_s[i+1], "-x_s["*string(i+1)*"]")
        CPRL.addVariable!(model, w_x_a_i)
        CPRL.addVariable!(model, minusX_s)
        vars = CPRL.AbstractIntVar[w_x_a_i, minusX_s, x_s[i]]
        transition = CPRL.SumToZero(vars, trailer)
        push!(model.constraints, transition)
    end

    # Validity: x_s[i] <= capacity
    # for i in 1:(n+1)
    #     validity = CPRL.LessOrEqualConstant(x_s[i], input.capacity)
    #     push!(model.constraints, validity)
    # end

    found = CPRL.solve!(model; variableHeuristic=selectVariable)

    if (found)
        oneSolution = last(model.solutions)
        output = solutionFromCPRL(oneSolution, input)
        if !benchmark
            printSolution(output)
        end
    end
end

function selectVariable(model::CPRL.CPModel)
    i = 1
    while CPRL.isbound(model.variables["x_a[" * string(i) * "]"])
        i += 1
    end
    return model.variables["x_a[" * string(i) * "]"]
end

function solutionFromCPRL(cprlSol::CPRL.Solution, input::InputData)
    taken = falses(input.numberOfItems)
    value = 0
    weight = 0
    for i in 1:input.numberOfItems
        if haskey(cprlSol, "x_a[" * string(i) * "]")
            taken[i] = convert(Bool, cprlSol["x_a[" * string(i) * "]"])
            if taken[i]
                value += input.items[i].value
                weight += input.items[i].weight
            end
        end
    end
    return Solution(taken, value, weight, false)
end

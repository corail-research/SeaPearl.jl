using Revise
using JuMP
using CPRL

struct Edge
    vertex1     :: Int
    vertex2     :: Int
end

struct InputData
    edges               :: Array{Edge}
    numberOfEdges       :: Int
    numberOfVertices    :: Int
end

struct OutputData
    numberOfColors      :: Int
    edgeColors          :: Array{Int}
    optimality          :: Bool
end

include("IOmanager.jl")


function outputFromCPRL(sol::CPRL.Solution; optimality=false)
    numberOfColors = 0
    edgeColors = Int[]

    for i in 1:length(keys(sol))
        color = sol[string(i)]
        if !(color in edgeColors)
            numberOfColors += 1
        end
        push!(edgeColors, color)
    end

    return OutputData(numberOfColors, edgeColors, optimality)
end



function solve_coloring(input_file; benchmark=false)
    
    input = getInputData(input_file)

    model = Model(CPRL.Optimizer)
    @variable(model, 1 <= x[1:input.numberOfVertices] <= input.numberOfVertices)

    degrees = zeros(Int, input.numberOfVertices)

    for e in input.edges
        @constraint(model, [x[e.vertex1], x[e.vertex2]] in CPRL.VariablesEquality(false))
        degrees[e.vertex1] += 1
        degrees[e.vertex2] += 1
    end

    MOI.set(model, MOI.RawParameter("degrees"), degrees)

    solution = optimize!(model)

    output = outputFromCPRL(solution)
    printSolution(output)
    
end

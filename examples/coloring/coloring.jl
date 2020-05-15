using DataStructures
using CPRL

mutable struct Vertex
    id          :: Int
    degree      :: Int
end

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

    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)
    x = CPRL.IntVar[]
    for i in 1:input.numberOfVertices
        push!(x, CPRL.IntVar(1, input.numberOfVertices, string(i), trailer))
        CPRL.addVariable!(model, last(x))
    end

    for e in input.edges
        push!(model.constraints, CPRL.NotEqual(x[e.vertex1], x[e.vertex2], trailer))
        # println(e.vertex1, " ", e.vertex2)
    end



    found = CPRL.solve!(model)

    if (found)
        oneSolution = last(model.solutions)
        output = outputFromCPRL(oneSolution)
        printSolution(output)


        

        while found
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)
            x = CPRL.IntVar[]
            for i in 1:input.numberOfVertices
                push!(x, CPRL.IntVar(1, output.numberOfColors-1, string(i), trailer))
                CPRL.addVariable!(model, last(x))
            end

            for e in input.edges
                push!(model.constraints, CPRL.NotEqual(x[e.vertex1], x[e.vertex2], trailer))
                # println(e.vertex1, " ", e.vertex2)
            end

            found = CPRL.solve!(model)
            if (found)
                oneSolution = last(model.solutions)
                output = outputFromCPRL(oneSolution)
                printSolution(output)
            end
        end

        writeSolution(output, "solution/"*string(input.numberOfVertices))
    end
    return
end

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

    for key in keys(sol)
        color = sol[key]
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

    # Breaking some symetries
    push!(model.constraints, CPRL.EqualConstant(x[1], 1, trailer))
    push!(model.constraints, CPRL.LessOrEqual(x[1], x[2], trailer))

    degrees = zeros(Int, input.numberOfVertices)

    for e in input.edges
        push!(model.constraints, CPRL.NotEqual(x[e.vertex1], x[e.vertex2], trailer))
        degrees[e.vertex1] += 1
        degrees[e.vertex2] += 1
    end

    sortedPermutation = sortperm(degrees; rev=true)

    numberOfColors = CPRL.IntVar(0, input.numberOfVertices, "numberOfColors", trailer)
    CPRL.addVariable!(model, numberOfColors)
    for var in x
        push!(model.constraints, CPRL.LessOrEqual(var, numberOfColors, trailer))
    end
    model.objective = numberOfColors

    function selectVariable(model::CPRL.CPModel, sortedPermutation, degrees)
        maxDegree = 0
        toReturn = nothing
        for i in sortedPermutation
            if !CPRL.isbound(model.variables[string(i)])
                if isnothing(toReturn)
                    toReturn = model.variables[string(i)]
                    maxDegree = degrees[i]
                end
                if degrees[i] < maxDegree
                    return toReturn
                end

                if length(model.variables[string(i)].domain) < length(toReturn.domain)
                    toReturn = model.variables[string(i)]
                end
            end
        end
        return toReturn
    end

    # model.limit.numberOfSolutions = 2000

    CPRL.solve!(model; variableHeuristic=((m) -> selectVariable(m, sortedPermutation, degrees)))
    if !benchmark
        for oneSolution in model.solutions
            output = outputFromCPRL(oneSolution)
            printSolution(output)
        end
    end
    return length(model.solutions)

    # try
        

        # if (found)


            

        #     # while found
        #     #     for y in x
        #     #         push!(model.constraints, CPRL.LessOrEqualConstant(y, output.numberOfColors-1, trailer))
        #     #     end
        #     #     CPRL.restoreInitialState!(trailer)
        #     #     found = CPRL.solve!(model; variableHeuristic=((m) -> selectVariable(m, sortedPermutation, degrees)))

        #     #     if (found)
        #     #         oneSolution = last(model.solutions)
        #     #         output = outputFromCPRL(oneSolution)
        #     #         if !benchmark
        #     #             printSolution(output)
        #     #         end
        #     #     end
        #     # end

        #     filename = last(split(input_file, "/"))

        #     if !benchmark
        #         # printSolution(output)
        #         writeSolution(output, "solution/"*filename)
                
        #     end
    #     # end
    # catch e
    #     if isa(e, InterruptException)
    #         if !benchmark
    #             filename = last(split(input_file, "/"))
    #             writeSolution(output, "solution/"*filename)
    #         end
    #     end
    #     rethrow(e)
    # end
    # return
end

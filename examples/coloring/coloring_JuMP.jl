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

function solve_coloring_MOI(input_file; benchmark=false)

    # use input data to fill the model
    input = getInputData(input_file)

    model = CPRL.Optimizer()

    for i in 1:input.numberOfVertices
        MOI.add_constrained_variable(model, MOI.Interval(1, input.numberOfVertices))
    end

    degrees = zeros(Int, input.numberOfVertices)

    for e in input.edges
        MOI.add_constraint(model, MOI.VectorOfVariables([MOI.VariableIndex(e.vertex1), MOI.VariableIndex(e.vertex2)]), CPRL.VariablesEquality(false))
        degrees[e.vertex1] += 1
        degrees[e.vertex2] += 1
    end

    sortedPermutation = sortperm(degrees; rev=true)

    # define the heuristic used for variable selection
    variableheuristic(m) = selectVariable(m, sortedPermutation, degrees)

    MOI.set(model, CPRL.VariableSelection(), variableheuristic)

    solution = MOI.optimize!(model)

    output = outputFromCPRL(solution)
    printSolution(output)
end


function solve_coloring_JuMP(input_file; benchmark=false)

    # use input data to fill the model
    input = getInputData(input_file)

    model = Model(CPRL.Optimizer)

    @variable(model, 1 <= x[1:input.numberOfVertices] <= input.numberOfVertices)

    degrees = zeros(Int, input.numberOfVertices)
    for e in input.edges
        @constraint(model, [x[e.vertex1], x[e.vertex2]] in CPRL.NotEqualSet())
        #update degrees
        degrees[e.vertex1] += 1
        degrees[e.vertex2] += 1
    end

    sortedPermutation = sortperm(degrees; rev=true)

    # define the heuristic used for variable selection
    variableheuristic(m) = selectVariable(m, sortedPermutation, degrees)

    MOI.set(model, CPRL.VariableSelection(), variableheuristic)

    optimize!(model)

    # output = outputFromCPRL(solution)
    # printSolution(output)
    println(model)

end
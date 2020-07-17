using JuMP

function selectVariableColoring(model::CPRL.CPModel, sortedPermutation, degrees)
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

@testset "Using CPRL with JuMP" begin
    @testset "GraphColoring model" begin
        model = Model(CPRL.Optimizer)

        numberOfVertices = 4


        @variable(model, 1 <= x[1:numberOfVertices] <= numberOfVertices)


        degrees = zeros(Int, numberOfVertices)

        @constraint(model, [x[1], x[2]] in CPRL.NotEqualSet())
        @constraint(model, [x[2], x[3]] in CPRL.NotEqualSet())
        @constraint(model, [x[2], x[4]] in CPRL.NotEqualSet())
            
        degrees[1] = 1
        degrees[2] = 3
        degrees[3] = 1
        degrees[4] = 1

        @variable(model, 1 <= y <= numberOfVertices)
        @constraint(model, x[1] <= y)
        @constraint(model, x[2] <= y)
        @constraint(model, x[3] <= y)
        @constraint(model, x[4] <= y)
        @objective(model, Min, y)

        sortedPermutation = sortperm(degrees; rev=true)

        # define the heuristic used for variable selection
        variableheuristic(m) = selectVariableColoring(m, sortedPermutation, degrees)

        MOI.set(model, CPRL.VariableSelection(), variableheuristic)

        optimize!(model)
        status = MOI.get(model, MOI.TerminationStatus())

        @test status == MOI.OPTIMAL
        @test has_values(model)
        @test value.(x) == [1, 2, 1, 1]
        @test value(y) == 2

        # cpmodel = MOI.get(model, CPRL.CPModel())

        @test length(collect(cpmodel.variables)) == 5
        @test length(cpmodel.constraints) == 7

        # println(MOI.get(model, CPRL.CPModel()))

        # output = outputFromCPRL(solution)
        # printSolution(output)
        println(model)
        println(status)
        println()
        println(value.(x))
        println(value(y))
    end
end
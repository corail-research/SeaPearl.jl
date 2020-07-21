using JuMP
using CPRL
using MathOptInterface

const MOI = MathOptInterface

struct GraphColoringVariableSelection  <: CPRL.AbstractVariableSelection{true}
    sortedPermutation
    degrees
end
function (vs::GraphColoringVariableSelection)(model::CPRL.CPModel)
    sortedPermutation, degrees = vs.sortedPermutation, vs.degrees
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


struct KnapsackVariableSelection <: CPRL.AbstractVariableSelection{true} end
function (::KnapsackVariableSelection)(model::CPRL.CPModel)
    i = 1
    while CPRL.isbound(model.variables[string(i)])
        i += 1
    end
    return model.variables[string(i)]
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
        variableheuristic = GraphColoringVariableSelection(sortedPermutation, degrees)
        # MOI.set(model, CPRL.MOIVariableSelectionAttribute(), variableheuristic)

        # Define the heuristic used for value selection
        # numberOfSteps = 0
        # valueheuristic = CPRL.BasicHeuristic()
        # MOI.set(model, CPRL.MOIValueSelection(), valueheuristic)
        # @test numberOfSteps == 5


        optimize!(model)
        status = MOI.get(model, MOI.TerminationStatus())

        @test status == MOI.OPTIMAL
        @test has_values(model)
        @test value.(x) == [1, 2, 1, 1] || value.(x) == [2, 1, 2, 2] #TODO: See Issue #43
        @test value(y) == 2
        println(model)
        println(status)
        println()
        println(value.(x))
        println(value(y))
    end

    @testset "Knapsack with JuMP" begin
        n = 4
        capacity = 11

        model = Model(CPRL.Optimizer)

        @variable(model, 0 <= x[1:n] <= 1)
        @constraint(model, 4 * x[1] + 5 * x[2] + 8 * x[3] + 3 * x[4] <= capacity)

        @expression(model, val_sum, 8 * x[1] + 10 * x[2] + 15 * x[3] + 4 * x[4])
        @objective(model, Min, -val_sum)

        variableheuristic = KnapsackVariableSelection()

        # MOI.set(model, CPRL.MOIVariableSelectionAttribute(), variableheuristic)

        optimize!(model)
        status = MOI.get(model, MOI.TerminationStatus())

        @test status == MOI.OPTIMAL
        @test has_values(model)
        @test value.(x) == [0, 0, 1, 1]
        @test value(val_sum) == 19
        @test value(4 * x[1] + 5 * x[2] + 8 * x[3] + 3 * x[4]) == 11

        println(model)
        println(status)
        println(has_values(model))
        println(value.(x))
    end
end
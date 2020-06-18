using DataStructures

@testset "dfs.jl" begin
    @testset "expandDfs!()" begin
        ### Checking status ###
        # :NodeLimitStop
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        model.limit.numberOfNodes = 1
        toCall = Stack{Function}()
        @test CPRL.expandDfs!(toCall, model, (model) -> nothing, CPRL.BasicHeuristic()) == :NodeLimitStop
        @test isempty(toCall)

        # :SolutionLimitStop
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        model.limit.numberOfSolutions = 0
        
        toCall = Stack{Function}()
        @test CPRL.expandDfs!(toCall, model, (model) -> nothing, CPRL.BasicHeuristic()) == :SolutionLimitStop
        @test isempty(toCall)

        # :Infeasible
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        
        x = CPRL.IntVar(2, 2, "x", trailer)
        y = CPRL.IntVar(3, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test CPRL.expandDfs!(toCall, model, (model) -> nothing, CPRL.BasicHeuristic()) == :Infeasible
        @test isempty(toCall)

        # :Feasible
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        
        x = CPRL.IntVar(2, 2, "x", trailer)
        y = CPRL.IntVar(2, 2, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test CPRL.expandDfs!(toCall, model, (model) -> nothing, CPRL.BasicHeuristic()) == :Feasible
        @test isempty(toCall)


        ### Checking stack ###
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        
        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test CPRL.expandDfs!(toCall, model, (model) -> x, CPRL.BasicHeuristic()) == :Feasible
        @test length(toCall) == 6

        @test pop!(toCall)(model) == :Feasible
        @test length(model.trailer.prior) == 1 # saveState!()

        @test pop!(toCall)(model) == :Feasible
        @test length(model.solutions) == 1 # Found a solution

        @test pop!(toCall)(model) == :Feasible
        @test length(model.trailer.prior) == 0 # restoreState!()

        @test pop!(toCall)(model) == :Feasible
        @test length(model.trailer.prior) == 1 # saveState!()

        @test pop!(toCall)(model) == :Feasible
        @test length(model.solutions) == 2 # Found another solution

        @test pop!(toCall)(model) == :Feasible
        @test length(model.trailer.prior) == 0 # restoreState!()
    end

    @testset "search!(::DFSearch)" begin
        ### Checking status ###
        # :LimitStop
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        model.limit.numberOfNodes = 1
        @test CPRL.search!(model, CPRL.DFSearch, () -> nothing) == :NodeLimitStop

        # :SolutionLimitStop
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        model.limit.numberOfSolutions = 0
        
        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        @test CPRL.search!(model, CPRL.DFSearch, () -> nothing) == :SolutionLimitStop

        # :Infeasible
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        
        x = CPRL.IntVar(2, 2, "x", trailer)
        y = CPRL.IntVar(3, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))

        @test CPRL.search!(model, CPRL.DFSearch, () -> nothing) == :Infeasible

        # :Optimal
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        
        x = CPRL.IntVar(2, 2, "x", trailer)
        y = CPRL.IntVar(2, 2, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))

        @test CPRL.search!(model, CPRL.DFSearch, () -> nothing) == :Optimal
        @test length(model.solutions) == 1


        ### Checking more complex solutions ###
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        
        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))

        @test CPRL.search!(model, CPRL.DFSearch, (model) -> x) == :Optimal
        @test length(model.solutions) == 2
        @test model.solutions[1] == Dict("x" => 3,"y" => 3)
        @test model.solutions[2] == Dict("x" => 2,"y" => 2)

    end

    @testset "search!() with a BasicHeuristic" begin

        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        
        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))

        @test CPRL.search!(model, CPRL.DFSearch, (model) -> x, CPRL.BasicHeuristic()) == :Optimal
        @test model.solutions[1] == Dict("x" => 3,"y" => 3)
        @test model.solutions[2] == Dict("x" => 2,"y" => 2)

        my_heuristic(x::CPRL.IntVar) = minimum(x.domain)
        @test CPRL.search!(model, CPRL.DFSearch, (model) -> x, CPRL.BasicHeuristic(my_heuristic)) == :Optimal
        @test model.solutions[1] == Dict("x" => 3,"y" => 3)
        @test model.solutions[2] == Dict("x" => 2,"y" => 2)

    end

    @testset "search!() with a LearnedHeuristic I" begin

        nothing

    end

    @testset "search!() with a LearnedHeuristic II" begin

        nothing

    end


end
@testset "lns.jl" begin
    @testset "expandLns!()" begin

        ### Testing returned value ###

        #:TimeLimitStop
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.searchingTime = 0

        x = SeaPearl.IntVar(1, 10, "x", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addObjective!(model, x)
        
        search = SeaPearl.LNSearch()
        SeaPearl.tic()
        @test SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :TimeLimitStop

        # :Infeasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(3, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch()
        @test SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :Infeasible

        # :Optimal
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch()
        @test SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :Optimal

        # :NonOptimal
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)
        model.limit.searchingTime = 1

        search = SeaPearl.LNSearch(repairLimits=Dict("searchingTime" => 0))
        @test SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :NonOptimal

        ### Test AssertionError ###

        # Ensure that model has objective
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(1, 10, "x", trailer)
        SeaPearl.addVariable!(model, x)
        
        search = SeaPearl.LNSearch()
        @test_throws AssertionError SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic())

        # Ensure that model hasn't a limit in numberOfNodes
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.numberOfNodes = 1000

        x = SeaPearl.IntVar(1, 10, "x", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch()
        @test_throws AssertionError SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic())

        # Ensure that model hasn't a limit in numberOfSolutions
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.numberOfSolutions = 100

        x = SeaPearl.IntVar(1, 10, "x", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch()
        @test_throws AssertionError SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic())

        # Ensure that: search.limitIterNoImprovement ≥ 1
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(1, 10, "x", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch(limitIterNoImprovement=0)
        @test_throws AssertionError SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic())

        # Ensure that: search.limitValuesToRemove ≤ count(values(model.branchable))
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(1, 10, "x", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addObjective!(model, x)
        y = SeaPearl.IntVar(1, 10, "y", trailer)
        SeaPearl.addVariable!(model, y)
        z = SeaPearl.IntVar(1, 10, "z", trailer)
        SeaPearl.addVariable!(model, z)

        search = SeaPearl.LNSearch(limitValuesToRemove=4)
        @test_throws AssertionError SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic())

        ### Test arguments ###

        # Ensure that time limits passed as argument are correctly managed (localSearchTimeLimit)
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
    
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch(limitIterNoImprovement=1, limitValuesToRemove = 2, repairLimits=Dict("searchingTime" => 1))
        status = SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) 
        @test model.limit.searchingTime == 1

        # Ensure that time limits passed as argument are correctly managed (globalTimeLimit)
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.searchingTime = 2

        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch()
        status = SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) 
        @test model.limit.searchingTime < 2

        # Ensure that time limits passed as argument are correctly managed (nothing)
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch(limitIterNoImprovement=1, limitValuesToRemove = 2)
        status = SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) 
        @test model.limit.searchingTime === nothing

        # Ensure that time limits passed as argument are correctly managed (localSearchTimeLimit and globalTimeLimit)
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.searchingTime = 10

        x = SeaPearl.IntVar(1, 100, "x", trailer)
        y = SeaPearl.IntVar(1, 100, "y", trailer)
        z = SeaPearl.IntVar(1, 100, "z", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.Equal(y, z, trailer))
        SeaPearl.addObjective!(model, z)
        
        search = SeaPearl.LNSearch(limitIterNoImprovement=20000, limitValuesToRemove = 3, repairLimits=Dict("searchingTime" => 10))
        status = SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) 
        @test model.limit.searchingTime < 10

        # Ensure that `limitValuesToRemove` works properly
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.searchingTime = 3

        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch(limitValuesToRemove = 1)
        status = SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) 
        @test status === :NonOptimal

        # Ensure that `limitIterNoImprovement` works properly
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.searchingTime = 10

        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch(limitIterNoImprovement=40000, limitValuesToRemove = 2)
        status = SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) 
        @test status === :Optimal
        @test model.limit.searchingTime < 10

        # Ensure that `repairLimits.numberOfNodes` works properly
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.searchingTime = 2

        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch(repairLimits=Dict("numberOfNodes" => 150), limitIterNoImprovement=10, limitValuesToRemove = 2)
        status = SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) 
        @test model.limit.numberOfNodes == 150

        # Ensure that `repairLimits.numberOfSolutions` works properly
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.searchingTime = 2

        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch(repairLimits=Dict("numberOfSolutions" => 150), limitIterNoImprovement=10, limitValuesToRemove = 2)
        status = SeaPearl.expandLns!(search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) 
        @test model.limit.numberOfSolutions == 150

    end

    @testset "destroy()" begin

        ### Remove some branchable variables ###
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 3, "y", trailer)
        z = SeaPearl.IntVar(1, 3, "z", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z; branchable=false)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.Equal(y, z, trailer))
        SeaPearl.addObjective!(model, z)

        model.limit.numberOfSolutions = 1
        status = SeaPearl.search!(model, SeaPearl.DFSearch(), SeaPearl.MinDomainVariableSelection())
        solution = model.statistics.solutions[1]
        numberOfValuesToRemove = 1
        objective = "z"

        SeaPearl.destroy!(model, solution, numberOfValuesToRemove, objective)

        # Check that 1 variable has been reassign and the other is unbounded
        @test SeaPearl.isbound(model.variables["x"]) != SeaPearl.isbound(model.variables["y"]) 
        # Check that the model has been reset
        @test isempty(model.statistics.solutions)
        # Check that the objective variable has been pruned
        @test 3 ∉ model.variables["z"].domain

        ### Remove all branchable variables ###
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 3, "y", trailer)
        z = SeaPearl.IntVar(1, 3, "z", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z; branchable=false)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.Equal(y, z, trailer))
        SeaPearl.addObjective!(model, z)

        model.limit.numberOfSolutions = 1
        status = SeaPearl.search!(model, SeaPearl.DFSearch(), SeaPearl.MinDomainVariableSelection())
        solution = model.statistics.solutions[1]
        numberOfValuesToRemove = 2
        objective = "z"

        SeaPearl.destroy!(model, solution, numberOfValuesToRemove, objective)

        # Check that all variables are unbounded
        @test !SeaPearl.isbound(model.variables["x"]) && !SeaPearl.isbound(model.variables["y"]) 
        # Check that the model has been reset
        @test isempty(model.statistics.solutions)
        # Check that the objective variable has been pruned
        @test 3 ∉ model.variables["z"].domain

        ### Remove 0 branchable variables ###
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 3, "y", trailer)
        z = SeaPearl.IntVar(1, 3, "z", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z; branchable=false)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.Equal(y, z, trailer))
        SeaPearl.addObjective!(model, z)

        model.limit.numberOfSolutions = 1
        status = SeaPearl.search!(model, SeaPearl.DFSearch(), SeaPearl.MinDomainVariableSelection())
        solution = model.statistics.solutions[1]
        numberOfValuesToRemove = 0
        objective = "z"

        SeaPearl.destroy!(model, solution, numberOfValuesToRemove, objective)

        # Check that all variables are bounded
        @test SeaPearl.isbound(model.variables["x"]) && SeaPearl.isbound(model.variables["y"]) 
        # Check that the model has been reset
        @test isempty(model.statistics.solutions)
        # Check that the objective variable has been pruned
        @test 3 ∉ model.variables["z"].domain

    end

    
    @testset "initroot(::LNSearch)" begin
        
        #:TimeLimitStop
        toCall = Stack{Function}()
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.searchingTime = 0

        x = SeaPearl.IntVar(1, 10, "x", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addObjective!(model, x)
        
        search = SeaPearl.LNSearch()
        SeaPearl.tic()
        @test SeaPearl.initroot!(toCall, search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :TimeLimitStop

        # :Infeasible
        toCall = Stack{Function}()
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(3, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch()
        @test SeaPearl.initroot!(toCall, search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :Infeasible

        # :Optimal
        toCall = Stack{Function}()
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch()
        @test SeaPearl.initroot!(toCall, search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :Optimal

        # :NonOptimal
        toCall = Stack{Function}()
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)
        model.limit.searchingTime = 1

        search = SeaPearl.LNSearch(repairLimits=Dict("searchingTime" => 0))
        @test SeaPearl.initroot!(toCall, search, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :NonOptimal

    end

    @testset "search!(::LNSearch)" begin
        
        #:TimeLimitStop
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.searchingTime = 0

        x = SeaPearl.IntVar(1, 10, "x", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addObjective!(model, x)
        
        search = SeaPearl.LNSearch()
        SeaPearl.tic()
        @test SeaPearl.search!(model, search, SeaPearl.MinDomainVariableSelection()) == :TimeLimitStop

        # :Infeasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(3, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch()
        @test SeaPearl.search!(model, search, SeaPearl.MinDomainVariableSelection()) == :Infeasible

        # TODO add :Optimal option for LNS?
    
        # :NonOptimal
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)
        model.limit.searchingTime = 1

        search = SeaPearl.LNSearch(repairLimits=Dict("searchingTime" => 0))
        @test SeaPearl.search!(model, search, SeaPearl.MinDomainVariableSelection()) == :NonOptimal

    end

    @testset "search!(::LNSearch) with a BasicHeuristic" begin
        
        #:TimeLimitStop
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.searchingTime = 0

        x = SeaPearl.IntVar(1, 10, "x", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addObjective!(model, x)
        
        search = SeaPearl.LNSearch()
        SeaPearl.tic()
        @test SeaPearl.search!(model, search, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :TimeLimitStop

        # :Infeasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(3, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)

        search = SeaPearl.LNSearch()
        @test SeaPearl.search!(model, search, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :Infeasible

        # TODO add :Optimal option for LNS?
    
        # :NonOptimal
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model, x)
        model.limit.searchingTime = 1

        search = SeaPearl.LNSearch(repairLimits=Dict("searchingTime" => 0))
        @test SeaPearl.search!(model, search, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :NonOptimal

    end
end
    
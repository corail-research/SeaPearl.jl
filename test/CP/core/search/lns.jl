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
    
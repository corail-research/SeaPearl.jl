@testset "isbinaryor.jl" begin
    
    @testset "isBinaryOr()" begin
        trailer = SeaPearl.Trailer()

        b = SeaPearl.BoolVar("b", trailer)
        x = SeaPearl.BoolVar("x", trailer)
        y = SeaPearl.BoolVar("y", trailer)

        constraint = SeaPearl.isBinaryOr(b, x, y, trailer)

        @test constraint in b.onDomainChange
        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::isBinaryOr)" begin

        @testset "b false - x,y unassigned" begin

            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryOr(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.assignedValue(x)
            @test !SeaPearl.assignedValue(y)
            @test prunedDomains == SeaPearl.CPModification("x" => [true], "y" => [true])
            @test !constraint.active.value
        end

        @testset "b false - x false, y unassigned" begin

            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryOr(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, false)
            SeaPearl.assign!(x, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.assignedValue(y)
            @test prunedDomains == SeaPearl.CPModification("y" => [true])
            @test !constraint.active.value

        end

        @testset "b false - x true, y unassigned" begin

            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryOr(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, false)
            SeaPearl.assign!(x, true)

            @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.assignedValue(y)
            @test prunedDomains == SeaPearl.CPModification("x" => [true], "y" => [true])
            @test !constraint.active.value
            
        end

        @testset "b unassigned - x true, y unassigned" begin

            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryOr(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.isbound(y)
            @test SeaPearl.assignedValue(b)
            @test prunedDomains == SeaPearl.CPModification("b" => [false])
            @test !constraint.active.value
            
        end

    end
end
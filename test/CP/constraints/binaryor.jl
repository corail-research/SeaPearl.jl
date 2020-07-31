@testset "binaryor.jl" begin
    
    @testset "BinaryOr()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.BoolVar("x", trailer)
        y = SeaPearl.BoolVar("y", trailer)

        constraint = SeaPearl.BinaryOr(x, y, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::BinaryOr)" begin

        @testset "x false, y unassigned" begin

            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryOr(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(y)
            @test prunedDomains == SeaPearl.CPModification("y" => [false])
            @test !constraint.active.value
            
        end

        @testset "x false, y false" begin

            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryOr(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, false)
            SeaPearl.assign!(y, false)

            @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.length(y.domain) == 0
            @test prunedDomains == SeaPearl.CPModification("y" => [false])
            @test !constraint.active.value
            
        end

        @testset "x true, y unassigned" begin

            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryOr(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification()
            @test !constraint.active.value
            
        end

    end
end
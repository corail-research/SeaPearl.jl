@testset "BinaryEquivalence.jl" begin
    
    @testset "BinaryEquivalence()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.BoolVar("x", trailer)
        y = SeaPearl.BoolVar("y", trailer)

        constraint = SeaPearl.BinaryEquivalence(x, y, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::BinaryEquivalence)" begin

        @testset "x true, y unassigned" begin

            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryEquivalence(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(y)
            @test prunedDomains == SeaPearl.CPModification("y" => [false])
            @test !constraint.active.value
            
        end

        @testset "x false, y unassigned" begin

            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryEquivalence(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("y" => [true])
            @test !constraint.active.value
            
        end

        @testset "x unassigned, y true" begin

            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryEquivalence(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(y, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [false])
            @test !constraint.active.value
            
        end

        @testset "x unassigned, y false" begin

            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryEquivalence(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(y, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [true])
            @test !constraint.active.value
            
        end

    end
end
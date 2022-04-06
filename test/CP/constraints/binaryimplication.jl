@testset "BinaryImplication.jl" begin
    
    @testset "BinaryImplication()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.BoolVar("x", trailer)
        y = SeaPearl.BoolVar("y", trailer)

        constraint = SeaPearl.BinaryImplication(x, y, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::BinaryImplication)" begin

        @testset "x true, y unassigned" begin

            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryImplication(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(y)
            @test prunedDomains == SeaPearl.CPModification("y" => [false])
            @test !constraint.active.value
            
        end

        @testset "x true, y false" begin

            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryImplication(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, true)
            SeaPearl.assign!(y, false)

            @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.length(y.domain) == 0
            @test prunedDomains == SeaPearl.CPModification("y" => [false])
            @test !constraint.active.value
            
        end

        @testset "x unassigned, y false" begin

            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryImplication(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(y, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.assignedValue(x)
            @test prunedDomains == SeaPearl.CPModification("x" => [true])
            @test !constraint.active.value
            
        end

        @testset "x false, y unassigned" begin

            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryImplication(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification()
            @test !constraint.active.value
            
        end

    end
end
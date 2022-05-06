@testset "binaryxor.jl" begin
    @testset "BinaryXor()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.BoolVar("x", trailer)
        y = SeaPearl.BoolVar("y", trailer)

        constraint = SeaPearl.BinaryXor(x, y, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::BinaryXor)" begin
        @testset "x false, y unassigned" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryXor(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(y)
            @test prunedDomains == SeaPearl.CPModification("y" => [false])
            @test !constraint.active.value
        end

        @testset "x true, y unassigned" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryXor(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.assignedValue(y)
            @test prunedDomains == SeaPearl.CPModification("y" => [true])
            @test !constraint.active.value
        end

        @testset "x unassigned, y false" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryXor(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(y, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(x)
            @test prunedDomains == SeaPearl.CPModification("x" => [false])
            @test !constraint.active.value
        end

        @testset "x unassigned, y true" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryXor(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(y, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.assignedValue(x)
            @test prunedDomains == SeaPearl.CPModification("x" => [true])
            @test !constraint.active.value
        end

        @testset "x false, y false" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryXor(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, false)
            SeaPearl.assign!(y, false)

            @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.length(y.domain) == 0
            @test prunedDomains == SeaPearl.CPModification("y" => [false])
            @test !constraint.active.value
        end

        @testset "x true, y true" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.BinaryXor(x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, true)
            SeaPearl.assign!(y, true)

            @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.length(y.domain) == 0
            @test prunedDomains == SeaPearl.CPModification("y" => [true])
            @test !constraint.active.value
        end
    end
end
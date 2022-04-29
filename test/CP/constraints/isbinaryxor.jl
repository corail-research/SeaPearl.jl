@testset "isbinaryxor.jl" begin
    @testset "isBinaryXor()" begin
        trailer = SeaPearl.Trailer()

        b = SeaPearl.BoolVar("b", trailer)
        x = SeaPearl.BoolVar("x", trailer)
        y = SeaPearl.BoolVar("y", trailer)

        constraint = SeaPearl.isBinaryXor(b, x, y, trailer)

        @test constraint in b.onDomainChange
        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::isBinaryXor)" begin
        @testset "b false - x,y unassigned" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.isbound(x)
            @test !SeaPearl.isbound(y)
            @test prunedDomains == SeaPearl.CPModification()
            @test constraint.active.value
        end

        @testset "b false - x false, y unassigned" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
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

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, false)
            SeaPearl.assign!(x, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(y)
            @test prunedDomains == SeaPearl.CPModification("y" => [false])
            @test !constraint.active.value
        end

        @testset "b false - x unassigned, y false" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, false)
            SeaPearl.assign!(y, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.assignedValue(x)
            @test prunedDomains == SeaPearl.CPModification("x" => [true])
            @test !constraint.active.value
        end

        @testset "b false - x unassigned, y true" begin

            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, false)
            SeaPearl.assign!(y, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(x)
            @test prunedDomains == SeaPearl.CPModification("x" => [false])
            @test !constraint.active.value
        end

        @testset "b false - x false, y false" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, false)
            SeaPearl.assign!(x, false)
            SeaPearl.assign!(y, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !constraint.active.value
        end

        @testset "b false - x true, y false" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, false)
            SeaPearl.assign!(x, true)
            SeaPearl.assign!(y, false)

            @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !constraint.active.value
        end

        @testset "b true - x false, y unassigned" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, true)
            SeaPearl.assign!(x, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(y)
            @test prunedDomains == SeaPearl.CPModification("y" => [false])
            @test !constraint.active.value
        end

        @testset "b true - x true, y unassigned" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, true)
            SeaPearl.assign!(x, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.assignedValue(y)
            @test prunedDomains == SeaPearl.CPModification("y" => [true])
            @test !constraint.active.value
        end

        @testset "b true - x unassigned, y false" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, true)
            SeaPearl.assign!(y, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(x)
            @test prunedDomains == SeaPearl.CPModification("x" => [false])
            @test !constraint.active.value
        end

        @testset "b true - x unassigned, y true" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, true)
            SeaPearl.assign!(y, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.assignedValue(x)
            @test prunedDomains == SeaPearl.CPModification("x" => [true])
            @test !constraint.active.value
        end

        @testset "b true - x false, y false" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, true)
            SeaPearl.assign!(x, false)
            SeaPearl.assign!(y, false)

            @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !constraint.active.value
        end

        @testset "b true - x true, y false" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, true)
            SeaPearl.assign!(x, true)
            SeaPearl.assign!(y, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !constraint.active.value
        end

        @testset "b true - x false, y true" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, true)
            SeaPearl.assign!(x, false)
            SeaPearl.assign!(y, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !constraint.active.value
        end

        @testset "b true - x true, y true" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, true)
            SeaPearl.assign!(x, true)
            SeaPearl.assign!(y, true)

            @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !constraint.active.value
        end

        @testset "b unassigned - x false, y false" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, false)
            SeaPearl.assign!(y, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.assignedValue(b)
            @test prunedDomains == SeaPearl.CPModification("b" => [true])
            @test !constraint.active.value
        end

        @testset "b unassigned - x false, y true" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, false)
            SeaPearl.assign!(y, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(b)
            @test prunedDomains == SeaPearl.CPModification("b" => [false])
            @test !constraint.active.value
        end

        @testset "b unassigned - x true, y false" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, true)
            SeaPearl.assign!(y, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(b)
            @test prunedDomains == SeaPearl.CPModification("b" => [false])
            @test !constraint.active.value
        end


        @testset "b unassigned - x true, y true" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, true)
            SeaPearl.assign!(y, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.assignedValue(b)
            @test prunedDomains == SeaPearl.CPModification("b" => [true])
            @test !constraint.active.value
        end

        @testset "b unassigned - x false, y unassigned" begin

            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.isbound(b)
            @test !SeaPearl.isbound(y)
            @test prunedDomains == SeaPearl.CPModification()
            @test constraint.active.value
        end

        @testset "b unassigned - x true, y unassigned" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(x, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.isbound(y)
            @test !SeaPearl.isbound(b)
            @test prunedDomains == SeaPearl.CPModification()
            @test constraint.active.value
        end

        @testset "b unassigned - x unassigned, y false" begin
            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.BoolVar("x", trailer)
            y = SeaPearl.BoolVar("y", trailer)

            constraint = SeaPearl.isBinaryXor(b, x, y, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(y, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test !SeaPearl.isbound(b)
            @test !SeaPearl.isbound(x)
            @test prunedDomains == SeaPearl.CPModification()
            @test constraint.active.value
        end

    end
end

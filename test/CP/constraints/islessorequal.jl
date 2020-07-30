
@testset "lessorqual.jl" begin
    
    @testset "isLessOrEqual()" begin
        trailer = SeaPearl.Trailer()
        b = SeaPearl.BoolVar("b", trailer)
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 6, "y", trailer)

        constraint = SeaPearl.isLessOrEqual(b, x, y, trailer)

        @test constraint in b.onDomainChange
        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::isLessOrEqual)" begin
        @testset "boolean true" begin

            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.IntVar(2, 6, "x", trailer)
            y = SeaPearl.IntVar(2, 3, "y", trailer)

            constraint = SeaPearl.isLessOrEqual(b, x, y, trailer)

            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, true)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

            @test length(x.domain) == 2
            @test !(5 in x.domain)
            @test 3 in x.domain
            @test prunedDomains == SeaPearl.CPModification("x" => [4, 5, 6])

            z = SeaPearl.IntVar(1, 1, "z", trailer)
            constraint2 = SeaPearl.isLessOrEqual(b, x, z, trailer)

            @test !SeaPearl.propagate!(constraint2, toPropagate, prunedDomains)

        end

        @testset "boolean false" begin

            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.IntVar(1, 4, "x", trailer)
            y = SeaPearl.IntVar(2, 6, "y", trailer)

            constraint = SeaPearl.isLessOrEqual(b, x, y, trailer)

            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            SeaPearl.assign!(b, false)

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

            @test length(y.domain) == 2
            @test length(x.domain) == 2
            @test !(4 in y.domain)
            @test !(5 in y.domain)
            @test 3 in y.domain
            @test !(1 in x.domain)
            @test !(2 in x.domain)
            @test 3 in x.domain
            @test prunedDomains == SeaPearl.CPModification("y" => [4, 5, 6], "x" => [1, 2])

            z = SeaPearl.IntVar(4, 4, "z", trailer)
            constraint2 = SeaPearl.isLessOrEqual(b, x, z, trailer)

            @test !SeaPearl.propagate!(constraint2, toPropagate, prunedDomains)

        end

        @testset "boolean unassigned - maxx <= miny" begin

            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.IntVar(2, 4, "x", trailer)
            y = SeaPearl.IntVar(4, 6, "y", trailer)

            constraint = SeaPearl.isLessOrEqual(b, x, y, trailer)

            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

            @test length(x.domain) == 3
            @test length(y.domain) == 3
            @test SeaPearl.assignedValue(b)
            @test prunedDomains == SeaPearl.CPModification("b" => [false])

        end

        @testset "boolean unassigned - minx > maxy" begin

            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.IntVar(5, 7, "x", trailer)
            y = SeaPearl.IntVar(2, 4, "y", trailer)

            constraint = SeaPearl.isLessOrEqual(b, x, y, trailer)

            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

            @test length(x.domain) == 3
            @test length(y.domain) == 3
            @test !SeaPearl.assignedValue(b)
            @test prunedDomains == SeaPearl.CPModification("b" => [true])

        end

        @testset "boolean unassigned - casual x & y" begin

            trailer = SeaPearl.Trailer()
            b = SeaPearl.BoolVar("b", trailer)
            x = SeaPearl.IntVar(2, 6, "x", trailer)
            y = SeaPearl.IntVar(3, 7, "y", trailer)

            constraint = SeaPearl.isLessOrEqual(b, x, y, trailer)

            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

            @test length(x.domain) == 5
            @test length(y.domain) == 5
            @test length(b.domain) == 2
            @test prunedDomains == SeaPearl.CPModification()

        end

    end
end

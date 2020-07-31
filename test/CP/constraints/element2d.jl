@testset "element2d.jl" begin
    
    @testset "Element2D()" begin
        trailer = SeaPearl.Trailer()

        matrix = [1 2 3 4;
                  5 6 7 8;
                  9 10 11 12]

        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 4, "y", trailer)
        z = SeaPearl.IntVar(1, 12, "z", trailer)

        constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange
        @test constraint.matrix == matrix
        @test constraint.active.value
    end

    @testset "propagate!(::Element2D)" begin

        @testset "x false, y unassigned" begin

            trailer = SeaPearl.Trailer()
            matrix = [3 2 3 4;
                      5 6 7 8;
                      9 10 11 8]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            y = SeaPearl.IntVar(1, 4, "y", trailer)
            z = SeaPearl.IntVar(1, 12, "z", trailer)

            constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("z" => [1, 12])
            @test constraint.active.value
            
        end

        @testset "x false, y unassigned" begin

            trailer = SeaPearl.Trailer()
            matrix = [3 2 3 4;
                      5 6 7 8;
                      9 10 11 8]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            y = SeaPearl.IntVar(1, 4, "y", trailer)
            z = SeaPearl.IntVar(1, 12, "z", trailer)

            constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("z" => [1, 12])
            @test constraint.active.value
            
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
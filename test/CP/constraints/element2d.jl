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

        @testset "Prune x & y to be valid indexes" begin

            trailer = SeaPearl.Trailer()
            matrix = [3 2 3 4;
                      5 6 7 8;
                      9 10 11 12]
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            y = SeaPearl.IntVar(1, 6, "y", trailer)
            z = SeaPearl.IntVar(1, 12, "z", trailer)

            constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [4, 5], "y" => [5, 6], "z" => [1])
            @test constraint.active.value
        
        end

        @testset "Prune z below" begin

            trailer = SeaPearl.Trailer()
            matrix = [3 2 3 4;
                      5 6 7 8;
                      9 10 11 12]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            y = SeaPearl.IntVar(1, 4, "y", trailer)
            z = SeaPearl.IntVar(1, 12, "z", trailer)

            constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("z" => [1])
            @test constraint.active.value
            
        end

        @testset "Prune z above" begin

            trailer = SeaPearl.Trailer()
            matrix = [1 2 3 4;
                      5 6 7 8;
                      9 10 9 7]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            y = SeaPearl.IntVar(1, 4, "y", trailer)
            z = SeaPearl.IntVar(1, 12, "z", trailer)

            constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("z" => [11, 12])
            @test constraint.active.value
            
        end

        @testset "Prune z below & above" begin

            trailer = SeaPearl.Trailer()
            matrix = [5 3 3 4;
                      5 6 7 8;
                      9 10 9 7]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            y = SeaPearl.IntVar(1, 4, "y", trailer)
            z = SeaPearl.IntVar(1, 12, "z", trailer)

            constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("z" => [1, 2, 11, 12])
            @test constraint.active.value
            
        end

        @testset "Prune z below & above" begin

            trailer = SeaPearl.Trailer()
            matrix = [5 3 3 4;
                      5 6 6 8;
                      9 10 9 6]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            y = SeaPearl.IntVar(1, 4, "y", trailer)
            z = SeaPearl.IntVar(1, 12, "z", trailer)

            constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            # 7 shouldn't be pruned 
            @test prunedDomains == SeaPearl.CPModification("z" => [1, 2, 11, 12])
            @test constraint.active.value
            
        end

        @testset "Prune x" begin

            trailer = SeaPearl.Trailer()
            matrix = [3 2 3 4;
                      5 6 7 8;
                      9 10 11 12]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            y = SeaPearl.IntVar(1, 4, "y", trailer)
            z = SeaPearl.IntVar(6, 12, "z", trailer)

            constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [1])
            @test constraint.active.value
            
        end

        @testset "Prune x & y" begin

            trailer = SeaPearl.Trailer()
            matrix = [3 2 3 4;
                      5 6 7 8;
                      9 10 11 12]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            y = SeaPearl.IntVar(1, 4, "y", trailer)
            z = SeaPearl.IntVar(10, 12, "z", trailer)

            constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [1, 2], "y" => [1])
            @test constraint.active.value
            
        end

        @testset "z assigned make x & y assigned" begin

            trailer = SeaPearl.Trailer()
            matrix = [3 2 3 4;
                      5 6 12 8;
                      9 10 11 10]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            y = SeaPearl.IntVar(1, 4, "y", trailer)
            z = SeaPearl.IntVar(12, 12, "z", trailer)

            constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(x) == 2
            @test SeaPearl.assignedValue(y) == 3
            @test prunedDomains == SeaPearl.CPModification("x" => [1, 3], "y" => [1, 2, 4])
            @test !constraint.active.value
            
        end

        @testset "z assigned make x & y pruned" begin

            trailer = SeaPearl.Trailer()
            matrix = [3 2 3 4;
                      5 12 12 8;
                      9 12 11 10]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            y = SeaPearl.IntVar(1, 4, "y", trailer)
            z = SeaPearl.IntVar(12, 12, "z", trailer)

            constraint = SeaPearl.Element2D(matrix, x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [1], "y" => [1, 4])
            @test !constraint.active.value
            
        end

    end
end
@testset "binarymaximum.jl" begin
    
    @testset "BinaryMaximumBC()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 4, "y", trailer)
        z = SeaPearl.IntVar(1, 12, "z", trailer)

        constraint = SeaPearl.BinaryMaximumBC(x, y, z, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::BinaryMaximumBC)" begin

        @testset "x too small" begin

            trailer = SeaPearl.Trailer()

            x = SeaPearl.IntVar(1, 3, "x", trailer)
            y = SeaPearl.IntVar(4, 6, "y", trailer)
            z = SeaPearl.IntVar(5, 12, "z", trailer)

            constraint = SeaPearl.BinaryMaximumBC(x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        
        end

        @testset "z too big" begin

            trailer = SeaPearl.Trailer()
            
            x = SeaPearl.IntVar(2, 4, "x", trailer)
            y = SeaPearl.IntVar(1, 4, "y", trailer)
            z = SeaPearl.IntVar(8, 12, "z", trailer)

            constraint = SeaPearl.BinaryMaximumBC(x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            
        end

        @testset "x too big" begin

            trailer = SeaPearl.Trailer()

            x = SeaPearl.IntVar(15, 18, "x", trailer)
            y = SeaPearl.IntVar(3, 6, "y", trailer)
            z = SeaPearl.IntVar(4, 12, "z", trailer)

            constraint = SeaPearl.BinaryMaximumBC(x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        
        end

        @testset "Prune x below" begin

            trailer = SeaPearl.Trailer()
            
            x = SeaPearl.IntVar(1, 6, "x", trailer)
            y = SeaPearl.IntVar(3, 4, "y", trailer)
            z = SeaPearl.IntVar(4, 12, "z", trailer)

            constraint = SeaPearl.BinaryMaximumBC(x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [1, 2, 3])
            @test constraint.active.value
            
        end

        @testset "Prune x above" begin

            trailer = SeaPearl.Trailer()
            
            x = SeaPearl.IntVar(5, 15, "x", trailer)
            y = SeaPearl.IntVar(3, 8, "y", trailer)
            z = SeaPearl.IntVar(4, 12, "z", trailer)

            constraint = SeaPearl.BinaryMaximumBC(x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [13, 14, 15])
            @test constraint.active.value
            
        end

        @testset "Prune y" begin

            trailer = SeaPearl.Trailer()
            
            x = SeaPearl.IntVar(4, 5, "x", trailer)
            y = SeaPearl.IntVar(4, 7, "y", trailer)
            z = SeaPearl.IntVar(1, 3, "z", trailer)

            constraint = SeaPearl.BinaryMaximumBC(x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("y" => [6, 7])
            @test constraint.active.value
            
        end

        @testset "Prune z" begin

            trailer = SeaPearl.Trailer()
            
            x = SeaPearl.IntVar(7, 10, "x", trailer)
            y = SeaPearl.IntVar(1, 6, "y", trailer)
            z = SeaPearl.IntVar(5, 12, "z", trailer)

            constraint = SeaPearl.BinaryMaximumBC(x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("z" => [5, 6, 11, 12])
            @test constraint.active.value
            
        end

        @testset "Prune x & y" begin

            trailer = SeaPearl.Trailer()
            
            x = SeaPearl.IntVar(7, 10, "x", trailer)
            y = SeaPearl.IntVar(4, 8, "y", trailer)
            z = SeaPearl.IntVar(1, 4, "z", trailer)

            constraint = SeaPearl.BinaryMaximumBC(x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [9, 10], "y" => [4, 5, 6])
            @test constraint.active.value
            
        end

        @testset "Assign x and deactivate" begin

            trailer = SeaPearl.Trailer()
            
            x = SeaPearl.IntVar(7, 10, "x", trailer)
            y = SeaPearl.IntVar(8, 8, "y", trailer)
            z = SeaPearl.IntVar(1, 4, "z", trailer)

            constraint = SeaPearl.BinaryMaximumBC(x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(x) == 8
            @test prunedDomains == SeaPearl.CPModification("x" => [7, 9, 10])
            @test !constraint.active.value
            
        end

        @testset "Assign x and deactivate" begin

            trailer = SeaPearl.Trailer()
            
            x = SeaPearl.IntVar(1, 10, "x", trailer)
            y = SeaPearl.IntVar(3, 3, "y", trailer)
            z = SeaPearl.IntVar(4, 4, "z", trailer)

            constraint = SeaPearl.BinaryMaximumBC(x, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(x) == 4
            @test prunedDomains == SeaPearl.CPModification("x" => [1, 2, 3, 5, 6, 7, 8, 9, 10])
            @test !constraint.active.value
            
        end

    end
end

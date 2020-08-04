@testset "element1d.jl" begin
    
    @testset "Element1D()" begin
        trailer = SeaPearl.Trailer()

        matrix = [1, 2, 3, 4]

        x = SeaPearl.IntVar(1, 3, "x", trailer)
        z = SeaPearl.IntVar(1, 12, "z", trailer)

        constraint = SeaPearl.Element1D(matrix, x, z, trailer)

        @test constraint in x.onDomainChange
        @test constraint in z.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::Element1D)" begin

        @testset "Prune x & y to be valid indexes" begin

            trailer = SeaPearl.Trailer()
            matrix = [3, 2, 3, 4]
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            z = SeaPearl.IntVar(1, 5, "z", trailer)

            constraint = SeaPearl.Element1D(matrix, x, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [5], "z" => [1, 5])
            @test constraint.active.value
        
        end

        @testset "Prune z below" begin

            trailer = SeaPearl.Trailer()
            matrix = [3, 2, 3, 12]
            x = SeaPearl.IntVar(2, 4, "x", trailer)
            z = SeaPearl.IntVar(1, 12, "z", trailer)

            constraint = SeaPearl.Element1D(matrix, x, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("z" => [1])
            @test constraint.active.value
            
        end

        @testset "Prune z above" begin

            trailer = SeaPearl.Trailer()
            matrix = [1, 10, 9, 7]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            z = SeaPearl.IntVar(1, 12, "z", trailer)

            constraint = SeaPearl.Element1D(matrix, x, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("z" => [11, 12])
            @test constraint.active.value
            
        end

        @testset "Prune z below & above" begin

            trailer = SeaPearl.Trailer()
            matrix = [3, 10, 9, 8]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            z = SeaPearl.IntVar(1, 12, "z", trailer)

            constraint = SeaPearl.Element1D(matrix, x, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("z" => [1, 2, 11, 12])
            @test constraint.active.value
            
        end

        @testset "Prune x" begin

            trailer = SeaPearl.Trailer()
            matrix = [5, 6, 12, 8]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            z = SeaPearl.IntVar(6, 12, "z", trailer)

            constraint = SeaPearl.Element1D(matrix, x, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [1])
            @test constraint.active.value
            
        end

        @testset "z assigned assigns x" begin

            trailer = SeaPearl.Trailer()
            matrix = [2, 12, 5, 8]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            z = SeaPearl.IntVar(12, 12, "z", trailer)

            constraint = SeaPearl.Element1D(matrix, x, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test SeaPearl.assignedValue(x) == 2
            @test prunedDomains == SeaPearl.CPModification("x" => [1, 3])
            @test !constraint.active.value
            
        end

        @testset "z assigned prunes x" begin

            trailer = SeaPearl.Trailer()
            matrix = [3, 12, 12, 4]
            x = SeaPearl.IntVar(1, 3, "x", trailer)
            z = SeaPearl.IntVar(12, 12, "z", trailer)

            constraint = SeaPearl.Element1D(matrix, x, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()

            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("x" => [1])
            @test !constraint.active.value
            
        end

    end
end
@testset "element1dVar.jl" begin

    @testset "Element1DVar()" begin
        trailer = SeaPearl.Trailer()

        y = SeaPearl.IntVar(0, 3, "y", trailer)
        z = SeaPearl.IntVar(4, 7, "z", trailer)

        SeaPearl.remove!(z.domain, 5)

        T0 = SeaPearl.IntVar(1, 9, "T0", trailer)
        SeaPearl.remove!(T0.domain, 2)
        SeaPearl.remove!(T0.domain, 3)
        SeaPearl.remove!(T0.domain, 4)
        SeaPearl.remove!(T0.domain, 5)
        SeaPearl.remove!(T0.domain, 7)
        SeaPearl.remove!(T0.domain, 8)
        SeaPearl.remove!(T0.domain, 9)
        T1 = SeaPearl.IntVar(1, 9, "T1", trailer)
        SeaPearl.remove!(T1.domain, 3)
        SeaPearl.remove!(T1.domain, 4)
        SeaPearl.remove!(T1.domain, 5)
        SeaPearl.remove!(T1.domain, 6)
        SeaPearl.remove!(T1.domain, 7)
        SeaPearl.remove!(T1.domain, 8)
        SeaPearl.remove!(T1.domain, 9)
        T2 = SeaPearl.IntVar(1, 9, "T2", trailer)
        SeaPearl.remove!(T2.domain, 2)
        SeaPearl.remove!(T2.domain, 3)
        SeaPearl.remove!(T2.domain, 4)
        SeaPearl.remove!(T2.domain, 5)
        SeaPearl.remove!(T2.domain, 6)
        SeaPearl.remove!(T2.domain, 7)
        SeaPearl.remove!(T2.domain, 8)
        T3 = SeaPearl.IntVar(1, 9, "T3", trailer)
        SeaPearl.remove!(T3.domain, 3)
        SeaPearl.remove!(T3.domain, 4)
        SeaPearl.remove!(T3.domain, 5)
        SeaPearl.remove!(T3.domain, 7)
        SeaPearl.remove!(T3.domain, 8)
        SeaPearl.remove!(T3.domain, 9)

        T = [T0, T1, T2, T3]

        constraint = SeaPearl.Element1DVar(T, y, z, trailer)

        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange
        @test constraint in T0.onDomainChange
        @test constraint in T1.onDomainChange
        @test constraint in T2.onDomainChange
        @test constraint in T3.onDomainChange
        @test constraint.array == T
        @test constraint.active.value
        @test constraint.yValues == [0, 1, 2, 3]
        @test all(in(i, constraint.zValues) for i in [4, 6, 7])
    end

    @testset "propagate!(::Element1DVar)" begin

        @testset "prune y and z" begin
            trailer = SeaPearl.Trailer()

            y = SeaPearl.IntVar(0, 3, "y", trailer)
            z = SeaPearl.IntVar(4, 7, "z", trailer)
            SeaPearl.remove!(z.domain, 5)
    
            T0 = SeaPearl.IntVar(1, 9, "T0", trailer)
            SeaPearl.remove!(T0.domain, 2)
            SeaPearl.remove!(T0.domain, 3)
            SeaPearl.remove!(T0.domain, 4)
            SeaPearl.remove!(T0.domain, 5)
            SeaPearl.remove!(T0.domain, 7)
            SeaPearl.remove!(T0.domain, 8)
            SeaPearl.remove!(T0.domain, 9)
            T1 = SeaPearl.IntVar(1, 9, "T1", trailer)
            SeaPearl.remove!(T1.domain, 3)
            SeaPearl.remove!(T1.domain, 4)
            SeaPearl.remove!(T1.domain, 5)
            SeaPearl.remove!(T1.domain, 6)
            SeaPearl.remove!(T1.domain, 7)
            SeaPearl.remove!(T1.domain, 8)
            SeaPearl.remove!(T1.domain, 9)
            T2 = SeaPearl.IntVar(1, 9, "T2", trailer)
            SeaPearl.remove!(T2.domain, 2)
            SeaPearl.remove!(T2.domain, 3)
            SeaPearl.remove!(T2.domain, 4)
            SeaPearl.remove!(T2.domain, 5)
            SeaPearl.remove!(T2.domain, 6)
            SeaPearl.remove!(T2.domain, 7)
            SeaPearl.remove!(T2.domain, 8)
            T3 = SeaPearl.IntVar(1, 9, "T3", trailer)
            SeaPearl.remove!(T3.domain, 3)
            SeaPearl.remove!(T3.domain, 4)
            SeaPearl.remove!(T3.domain, 5)
            SeaPearl.remove!(T3.domain, 7)
            SeaPearl.remove!(T3.domain, 8)
            SeaPearl.remove!(T3.domain, 9)
    
            T = [T0, T1, T2, T3]
    
            constraint = SeaPearl.Element1DVar(T, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()
            
            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("y" => [1, 2], "z" => [4, 7],)
            @test constraint.active.value
        end

        @testset "prune only y" begin
            trailer = SeaPearl.Trailer()

            y = SeaPearl.IntVar(0, 3, "y", trailer)
            z = SeaPearl.IntVar(4, 7, "z", trailer)
            SeaPearl.remove!(z.domain, 5)
    
            T0 = SeaPearl.IntVar(4, 7, "T0", trailer)
            SeaPearl.remove!(T0.domain, 5)
            T1 = SeaPearl.IntVar(1, 9, "T1", trailer)
            SeaPearl.remove!(T1.domain, 3)
            SeaPearl.remove!(T1.domain, 4)
            SeaPearl.remove!(T1.domain, 5)
            SeaPearl.remove!(T1.domain, 6)
            SeaPearl.remove!(T1.domain, 7)
            SeaPearl.remove!(T1.domain, 8)
            SeaPearl.remove!(T1.domain, 9)
            T2 = SeaPearl.IntVar(1, 9, "T2", trailer)
            SeaPearl.remove!(T2.domain, 2)
            SeaPearl.remove!(T2.domain, 3)
            SeaPearl.remove!(T2.domain, 4)
            SeaPearl.remove!(T2.domain, 5)
            SeaPearl.remove!(T2.domain, 6)
            SeaPearl.remove!(T2.domain, 7)
            SeaPearl.remove!(T2.domain, 8)
            T3 = SeaPearl.IntVar(4, 7, "T3", trailer)
            SeaPearl.remove!(T3.domain, 5)
    
            T = [T0, T1, T2, T3]
    
            constraint = SeaPearl.Element1DVar(T, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()
            
            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("y" => [1, 2])
            @test constraint.active.value
        end

        @testset "prune y and z" begin
            trailer = SeaPearl.Trailer()

            y = SeaPearl.IntVar(0, 3, "y", trailer)
            z = SeaPearl.IntVar(4, 7, "z", trailer)
            SeaPearl.remove!(z.domain, 5)
    
            T0 = SeaPearl.IntVar(6, 6, "T0", trailer)
            T1 = SeaPearl.IntVar(1, 9, "T1", trailer)
            SeaPearl.remove!(T1.domain, 3)
            SeaPearl.remove!(T1.domain, 4)
            SeaPearl.remove!(T1.domain, 5)
            SeaPearl.remove!(T1.domain, 6)
            SeaPearl.remove!(T1.domain, 7)
            SeaPearl.remove!(T1.domain, 8)
            SeaPearl.remove!(T1.domain, 9)
            T2 = SeaPearl.IntVar(1, 9, "T2", trailer)
            SeaPearl.remove!(T2.domain, 2)
            SeaPearl.remove!(T2.domain, 3)
            SeaPearl.remove!(T2.domain, 4)
            SeaPearl.remove!(T2.domain, 5)
            SeaPearl.remove!(T2.domain, 6)
            SeaPearl.remove!(T2.domain, 7)
            SeaPearl.remove!(T2.domain, 8)
            T3 = SeaPearl.IntVar(6, 6, "T3", trailer)
    
            T = [T0, T1, T2, T3]
    
            constraint = SeaPearl.Element1DVar(T, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()
            
            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("y" => [1, 2], "z" => [4, 7])
            @test constraint.active.value
        end

        @testset "prune y and T" begin
            trailer = SeaPearl.Trailer()

            y = SeaPearl.IntVar(0, 3, "y", trailer)
            z = SeaPearl.IntVar(4, 7, "z", trailer)
            SeaPearl.remove!(z.domain, 5)
    
            T0 = SeaPearl.IntVar(9, 9, "T0", trailer)
            T1 = SeaPearl.IntVar(2, 9, "T1", trailer)
            T2 = SeaPearl.IntVar(1, 1, "T2", trailer)
            T3 = SeaPearl.IntVar(2, 9, "T3", trailer)
            SeaPearl.remove!(T3.domain, 3)
            SeaPearl.remove!(T3.domain, 4)
            SeaPearl.remove!(T3.domain, 5)
            SeaPearl.remove!(T3.domain, 6)
            SeaPearl.remove!(T3.domain, 7)
            SeaPearl.remove!(T3.domain, 8)
            T = [T0, T1, T2, T3]
    
            constraint = SeaPearl.Element1DVar(T, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()
            
            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("y" => [0, 2, 3], "T1" => [2, 3, 5, 8, 9])
            @test !constraint.active.value
        end

        @testset "prune z only" begin
            trailer = SeaPearl.Trailer()

            y = SeaPearl.IntVar(0, 3, "y", trailer)
            z = SeaPearl.IntVar(4, 7, "z", trailer)
            SeaPearl.remove!(z.domain, 5)
    
            T0 = SeaPearl.IntVar(5, 6, "T0", trailer)
            T1 = SeaPearl.IntVar(6, 6, "T1", trailer)
            T2 = SeaPearl.IntVar(7, 7, "T2", trailer)
            T3 = SeaPearl.IntVar(7, 8, "T3", trailer)
    
            T = [T0, T1, T2, T3]
    
            constraint = SeaPearl.Element1DVar(T, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()
            
            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("z" => [4])
            @test constraint.active.value
        end

        @testset "y bound, prune z and T" begin
            trailer = SeaPearl.Trailer()

            y = SeaPearl.IntVar(2, 2, "y", trailer)
            z = SeaPearl.IntVar(4, 7, "z", trailer)
            SeaPearl.remove!(z.domain, 5)
    
            T2 = SeaPearl.IntVar(1, 9, "T2", trailer)
            SeaPearl.remove!(T2.domain, 6)

            T = [T2]
    
            constraint = SeaPearl.Element1DVar(T, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()
            
            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("z" => [6], "T2" => [1, 2, 3, 5, 9, 8])
            @test !constraint.active.value
        end

        @testset "z bound, prune y and T" begin
            trailer = SeaPearl.Trailer()

            y = SeaPearl.IntVar(0, 3, "y", trailer)
            z = SeaPearl.IntVar(4, 4, "z", trailer)

            T0 = SeaPearl.IntVar(3, 4, "T0", trailer)
            T1 = SeaPearl.IntVar(5, 5, "T1", trailer)
            T2 = SeaPearl.IntVar(1, 3, "T2", trailer)
            T3 = SeaPearl.IntVar(5, 6, "T3", trailer)

            T = [T0, T1, T2, T3]

            constraint = SeaPearl.Element1DVar(T, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()
            
            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("y" => [1,2,3], "T0" => [3])
            @test !constraint.active.value
        end

        @testset "z and y bound, filter T" begin
            trailer = SeaPearl.Trailer()

            y = SeaPearl.IntVar(1, 1, "y", trailer)
            z = SeaPearl.IntVar(4, 4, "z", trailer)

            T1 = SeaPearl.IntVar(1, 5, "T1", trailer)
            SeaPearl.remove!(T1.domain, 2)

            T = [T1]

            constraint = SeaPearl.Element1DVar(T, y, z, trailer)
            toPropagate = Set{SeaPearl.Constraint}()
            prunedDomains = SeaPearl.CPModification()
            
            @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            @test prunedDomains == SeaPearl.CPModification("T1" => [1, 5, 3])
            @test !constraint.active.value

        end
    end
end
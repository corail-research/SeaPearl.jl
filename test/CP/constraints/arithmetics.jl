@testset "arithmetics.jl" begin
    @testset "Addition()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        
        z = SeaPearl.IntVar(2, 3, "z", trailer)
        
        constraint = SeaPearl.Addition(x, y, z, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange

        @test constraint.active.value
        @test constraint.numberOfFreeVars.value == 3
        @test constraint.sumOfFixedVars.value == 0
        @test constraint.freeIds == [1, 2, 3]
    end
    @testset "propagate!(::Addition)" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(0, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 5, "y", trailer)

        z = SeaPearl.IntVar(0, 1, "z", trailer)
        
        constraint = SeaPearl.Addition(x, y, z, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 1
        @test 1 in y.domain
        @test !(3 in x.domain)
        @test !(2 in y.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "x"  => [1,2,3],
            "y"  => [2,3,4,5],
            "-z" => [0],
            "z" => [0]
        )
    end

    @testset "Subtraction()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        
        z = SeaPearl.IntVar(2, 3, "z", trailer)
        
        constraint = SeaPearl.Subtraction(x, y, z, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange

        @test constraint.active.value
        @test constraint.numberOfFreeVars.value == 3
        @test constraint.sumOfFixedVars.value == 0
        @test constraint.freeIds == [1, 2, 3]
    end
    @testset "propagate!(::Subtraction)" begin
        trailer = SeaPearl.Trailer()
        
        x = SeaPearl.IntVar(4, 5, "x", trailer)
        y = SeaPearl.IntVar(0, 3, "y", trailer)
        

        z = SeaPearl.IntVar(0, 1, "z", trailer)
        
        constraint = SeaPearl.Subtraction(x, y, z, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 1
        @test 4 in x.domain
        @test !(2 in y.domain)
        @test !(5 in x.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "x"  => [5],
            "y"  => [0,1,2],
            "-y"  => [0,-1,-2],
            "-z" => [0],
            "z" => [0]
        )
    end

    @testset "Multiplication()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        
        z = SeaPearl.IntVar(2, 6, "z", trailer)
        
        constraint = SeaPearl.Multiplication(x, y, z, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange

        @test constraint.active.value
    end

    @testset "propagate!(::Multiplication)" begin
        trailer = SeaPearl.Trailer()
        
        x = SeaPearl.IntVar(2, 4, "x", trailer)
        y = SeaPearl.IntVar(3, 10, "y", trailer)

        z = SeaPearl.IntVar(8, 9, "z", trailer)
        
        constraint = SeaPearl.Multiplication(x, y, z, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 2
        @test !(10 in y.domain)
        @test !(4 in x.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "x"  => [4],
            "y"  => [5,6,7,8,9,10]
        )


        trailer = SeaPearl.Trailer()
        
        x = SeaPearl.IntVar(-2, 4, "x", trailer)
        y = SeaPearl.IntVar(-5, -1, "y", trailer)

        z = SeaPearl.IntVar(7, 12, "z", trailer)
        
        constraint = SeaPearl.Multiplication(x, y, z, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        
        @test length(y.domain) == 3
        @test !(0 in y.domain)
        @test !(4 in x.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "x"  => [0,1,2,3,4],
            "y"  => [-2, -1],
            "z" => [11,12]
        )
    end

    @testset "Division()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        
        z = SeaPearl.IntVar(2, 6, "z", trailer)
        
        constraint = SeaPearl.Division(x, y, z, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange

        @test constraint.active.value
    end

    @testset "propagate!(::Division)" begin
        trailer = SeaPearl.Trailer()
        
        x = SeaPearl.IntVar(5, 7, "x", trailer)
        y = SeaPearl.IntVar(3, 5, "y", trailer)

        z = SeaPearl.IntVar(2, 4, "z", trailer)
        
        constraint = SeaPearl.Division(x, y, z, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(z.domain) == 1
        @test !(10 in y.domain)
        @test !(4 in z.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "x" => [5],
            "y"  => [4,5],
            "z"  => [3,4]
        )

        trailer = SeaPearl.Trailer()
        
        x = SeaPearl.IntVar(2, 8, "x", trailer)
        y = SeaPearl.IntVar(-5, 2, "y", trailer)

        z = SeaPearl.IntVar(0, 2, "z", trailer)
        
        constraint = SeaPearl.Division(x, y, z, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 2
        @test !(0 in y.domain)
        @test !(8 in x.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "x"  => [6,7,8],
            "y"  => [0,-5,-4,-3,-2,-1],
            "z" => [0]
        )
    end

    @testset "Modulo()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        
        z = SeaPearl.IntVar(2, 6, "z", trailer)
        
        constraint = SeaPearl.Modulo(x, y, z, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange

        @test constraint.active.value
    end

    @testset "propagate!(::Modulo)" begin
        trailer = SeaPearl.Trailer()
        
        x = SeaPearl.IntVar(5, 10, "x", trailer)
        y = SeaPearl.IntVar(0, 3, "y", trailer)

        z = SeaPearl.IntVar(2, 5, "z", trailer)
        
        constraint = SeaPearl.Modulo(x, y, z, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(z.domain) == 1
        @test !(0 in y.domain)
        @test !(4 in z.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "y"  => [0],
            "z"  => [3,4,5]
        )

    end

    # @testset "Distance" begin
    #     trailer = SeaPearl.Trailer()

    #     x = SeaPearl.IntVar(2, 6, "x", trailer)
    #     y = SeaPearl.IntVar(2, 3, "y", trailer)
        
    #     z = SeaPearl.IntVar(2, 3, "z", trailer)
        
    #     constraint = SeaPearl.Distance(x, y, z, trailer)

    #     @test constraint in z.onDomainChange

    #     @test constraint.active.value
    # end
    # @testset "propagate!(::Distance)" begin
    #     trailer = SeaPearl.Trailer()
        
    #     x = SeaPearl.IntVar(4, 8, "x", trailer)
    #     y = SeaPearl.IntVar(0, 4, "y", trailer)
        
    #     z = SeaPearl.IntVar(0, 2, "z", trailer)
        
    #     constraint = SeaPearl.Distance(x, y, z, trailer)

    #     toPropagate = Set{SeaPearl.Constraint}()
    #     prunedDomains = SeaPearl.CPModification()

    #     @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
    #     println(z)

    #     @test length(y.domain) == 3
    #     @test 4 in x.domain
    #     @test !(0 in y.domain)
    #     @test !(8 in x.domain)
    #     @test prunedDomains == SeaPearl.CPModification(
    #         "x"  => [5],
    #         "y"  => [0,1,2],
    #         "-y"  => [0,-1,-2],
    #         "-z" => [0],
    #         "z" => [0]
    #     )
    # end

end
using CPRL

@testset "equal.jl" begin
    @testset "EqualConstant()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)

        constraint = CPRL.EqualConstant(x, 3, trailer)

        @test constraint in x.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::EqualConstant)" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)

        constraint = CPRL.EqualConstant(x, 3, trailer)

        toPropagate = Set{CPRL.Constraint}()
        prunedDomains = CPRL.CPModification()

        @test CPRL.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 1
        @test 3 in x.domain
        @test !(2 in x.domain)
        @test prunedDomains == CPRL.CPModification("x" => [2, 4, 5, 6])


        cons2 = CPRL.EqualConstant(x, 2, trailer)

        @test !CPRL.propagate!(cons2, toPropagate, prunedDomains)

        @test isempty(x.domain)

        y = CPRL.IntVar(2, 6, "y", trailer)
        constraint1 = CPRL.EqualConstant(y, 3, trailer)
        constraint2 = CPRL.EqualConstant(y, 4, trailer)

        toPropagate2 = Set{CPRL.Constraint}()
        CPRL.propagate!(constraint1, toPropagate2, prunedDomains)
        
        @test constraint2 in toPropagate2

    end

    @testset "pruneEqual!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        y = CPRL.IntVar(5, 8, "y", trailer)

        CPRL.pruneEqual!(y, x)

        @test length(y.domain) == 2
        @test !(8 in y.domain) && 5 in y.domain && 6 in y.domain


    end

    @testset "propagate!(::Equal)" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        y = CPRL.IntVar(5, 8, "y", trailer)

        constraint = CPRL.Equal(x, y, trailer)
        toPropagate = Set{CPRL.Constraint}()
        prunedDomains = CPRL.CPModification()

        @test CPRL.propagate!(constraint, toPropagate, prunedDomains)


        @test length(x.domain) == 2
        @test length(y.domain) == 2
        @test !(2 in x.domain) && 5 in x.domain && 6 in x.domain
        @test !(8 in y.domain) && 5 in y.domain && 6 in y.domain
        @test prunedDomains == CPRL.CPModification("x" => [2, 3, 4],"y" => [7, 8])

        # Propagation test
        z = CPRL.IntVar(5, 15, "z", trailer)
        constraint2 = CPRL.Equal(y, z, trailer)
        CPRL.propagate!(constraint2, toPropagate, prunedDomains)

        # Domain not reduced => not propagation
        @test !(constraint in toPropagate)
        @test !(constraint2 in toPropagate)

        # Domain reduced => propagation
        CPRL.remove!(z.domain, 5)
        CPRL.propagate!(constraint2, toPropagate, prunedDomains)
        @test constraint in toPropagate
        @test !(constraint2 in toPropagate)

        #Unfeasible test
        t = CPRL.IntVar(15, 30, "t", trailer)
        constraint3 = CPRL.Equal(z, t, trailer)
        @test !CPRL.propagate!(constraint3, toPropagate, prunedDomains)
    end
end

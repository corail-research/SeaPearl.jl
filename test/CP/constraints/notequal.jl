using CPRL

@testset "notequal.jl" begin
    @testset "NotEqualConstant()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)

        constraint = CPRL.NotEqualConstant(x, 3)

        @test constraint in x.onDomainChange
        @test constraint.active
    end
    @testset "propagate!(::NotEqualConstant)" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)

        constraint = CPRL.NotEqualConstant(x, 3)

        toPropagate = Set{CPRL.Constraint}()
        prunedDomains = CPRL.CPModification()

        @test CPRL.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 4
        @test 2 in x.domain
        @test !(3 in x.domain)
        @test prunedDomains == CPRL.CPModification("x" => [3])

        y = CPRL.IntVar(2, 2, "y", trailer)

        cons2 = CPRL.NotEqualConstant(y, 2)

        @test !CPRL.propagate!(cons2, toPropagate, prunedDomains)

        @test isempty(y.domain)

        z = CPRL.IntVar(2, 6, "z", trailer)
        constraint1 = CPRL.NotEqualConstant(z, 3)
        constraint2 = CPRL.NotEqualConstant(z, 4)

        toPropagate2 = Set{CPRL.Constraint}()
        CPRL.propagate!(constraint1, toPropagate2, prunedDomains)
        
        @test constraint2 in toPropagate2

    end

    @testset "propagate!(::NotEqual)" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        y = CPRL.IntVar(5, 8, "y", trailer)

        constraint = CPRL.NotEqual(x, y)
        toPropagate = Set{CPRL.Constraint}()
        prunedDomains = CPRL.CPModification()

        @test CPRL.propagate!(constraint, toPropagate, prunedDomains)


        @test length(x.domain) == 5
        @test length(y.domain) == 4
        @test prunedDomains == CPRL.CPModification()

        # Propagation test
        z = CPRL.IntVar(5, 6, "z", trailer)
        constraint2 = CPRL.NotEqual(y, z)
        @test CPRL.propagate!(constraint2, toPropagate, prunedDomains)

        # Domain not reduced => not propagation
        @test !(constraint in toPropagate)
        @test !(constraint2 in toPropagate)

        # Domain reduced => propagation
        CPRL.remove!(z.domain, 6)
        @test CPRL.propagate!(constraint2, toPropagate, prunedDomains)
        @test constraint in toPropagate
        @test !(constraint2 in toPropagate)
        @test prunedDomains == CPRL.CPModification("y" => [5])
        @test length(y.domain) == 3

        #Unfeasible test
        t = CPRL.IntVar(5, 5, "t", trailer)
        constraint3 = CPRL.NotEqual(z, t)
        @test !CPRL.propagate!(constraint3, toPropagate, prunedDomains)
    end
end

using CPRL

@testset "equal.jl" begin
    @testset "EqualConstant()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, trailer)

        constraint = CPRL.EqualConstant(x, 3)

        @test constraint in x.onDomainChange
        @test constraint.active
    end
    @testset "propagate!(::EqualConstant)" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, trailer)

        constraint = CPRL.EqualConstant(x, 3)

        toPropagate = Set{CPRL.Constraint}()

        CPRL.propagate!(constraint, toPropagate)

        @test length(x.domain) == 1
        @test 3 in x.domain
        @test !(2 in x.domain)


        cons2 = CPRL.EqualConstant(x, 2)

        CPRL.propagate!(cons2, toPropagate)

        @test isempty(x.domain)

        y = CPRL.IntVar(2, 6, trailer)
        constraint1 = CPRL.EqualConstant(y, 3)
        constraint2 = CPRL.EqualConstant(y, 4)

        toPropagate2 = Set{CPRL.Constraint}()
        CPRL.propagate!(constraint1, toPropagate2)
        
        @test constraint2 in toPropagate2

    end

    @testset "pruneEqual!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, trailer)
        y = CPRL.IntVar(5, 8, trailer)

        CPRL.pruneEqual!(y, x)

        @test length(y.domain) == 2
        @test !(8 in y.domain) && 5 in y.domain && 6 in y.domain


    end

    @testset "propagate!(::Equal)" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, trailer)
        y = CPRL.IntVar(5, 8, trailer)

        constraint = CPRL.Equal(x, y)
        toPropagate = Set{CPRL.Constraint}()
        CPRL.propagate!(constraint, toPropagate)


        @test length(x.domain) == 2
        @test length(y.domain) == 2
        @test !(2 in x.domain) && 5 in x.domain && 6 in x.domain
        @test !(8 in y.domain) && 5 in y.domain && 6 in y.domain

        # Propagation test
        z = CPRL.IntVar(5, 15, trailer)
        constraint2 = CPRL.Equal(y, z)
        CPRL.propagate!(constraint2, toPropagate)

        # Domain not reduced => not propagation
        @test !(constraint in toPropagate)
        @test !(constraint2 in toPropagate)

        # Domain reduced => propagation
        CPRL.remove!(z.domain, 5)
        CPRL.propagate!(constraint2, toPropagate)
        @test constraint in toPropagate
        @test !(constraint2 in toPropagate)
    end
end

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
end

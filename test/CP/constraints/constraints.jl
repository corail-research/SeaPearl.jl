
@testset "constraints" begin
    include("equal.jl")
    include("notequal.jl")
    include("lessorequal.jl")
    include("greaterorequal.jl")

    @testset "addOnDomainChange!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        ax = CPRL.IntVarViewMul(x, 3, "ax")

        constraint = CPRL.EqualConstant(ax, 6, trailer)

        CPRL.addOnDomainChange!(ax, constraint)

        @test constraint in x.onDomainChange
    end

    @testset "addToPropagate!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        ax = CPRL.IntVarViewMul(x, 3, "ax")

        constraint = CPRL.EqualConstant(ax, 6, trailer)

        toPropagate = Set{CPRL.Constraint}()
        constraints = Array{CPRL.Constraint}([constraint])

        CPRL.addToPropagate!(toPropagate, constraints)

        @test constraint in toPropagate

        toPropagate = Set{CPRL.Constraint}()
        CPRL.setValue!(constraint.active, false)
        @test !(constraint in toPropagate)
    end

    @testset "triggerDomainChange!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        ax = CPRL.IntVarViewMul(x, 3, "ax")

        constraint = CPRL.EqualConstant(ax, 6, trailer)

        toPropagate = Set{CPRL.Constraint}()


        CPRL.triggerDomainChange!(toPropagate, ax)

        @test constraint in toPropagate
    end
end
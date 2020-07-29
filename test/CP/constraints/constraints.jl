
@testset "constraints" begin
    include("equal.jl")
    include("notequal.jl")
    include("lessorequal.jl")
    include("greaterorequal.jl")
    include("sumtozero.jl")
    include("islessorequal.jl")

    @testset "addOnDomainChange!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        ax = SeaPearl.IntVarViewMul(x, 3, "ax")

        y = SeaPearl.IntVar(8, 9, "y", trailer)
        b = SeaPearl.BoolVar("b", trailer)

        constraint = SeaPearl.EqualConstant(ax, 6, trailer)
        reified_constraint = SeaPearl.isLessOrEqual(b, x, y, trailer)

        SeaPearl.addOnDomainChange!(ax, constraint)

        @test constraint in x.onDomainChange

        SeaPearl.addOnDomainChange!(b, reified_constraint)

        @test reified_constraint in b.onDomainChange
    end

    @testset "addToPropagate!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        ax = SeaPearl.IntVarViewMul(x, 3, "ax")

        constraint = SeaPearl.EqualConstant(ax, 6, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        constraints = Array{SeaPearl.Constraint}([constraint])

        SeaPearl.addToPropagate!(toPropagate, constraints)

        @test constraint in toPropagate

        toPropagate = Set{SeaPearl.Constraint}()
        SeaPearl.setValue!(constraint.active, false)
        @test !(constraint in toPropagate)
    end

    @testset "triggerDomainChange!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        ax = SeaPearl.IntVarViewMul(x, 3, "ax")

        y = SeaPearl.IntVar(8, 9, "y", trailer)
        b = SeaPearl.BoolVar("b", trailer)

        constraint = SeaPearl.EqualConstant(ax, 6, trailer)
        reified_constraint = SeaPearl.isLessOrEqual(b, x, y, trailer)

        toPropagate = Set{SeaPearl.Constraint}()

        SeaPearl.triggerDomainChange!(toPropagate, ax)

        @test constraint in toPropagate

        SeaPearl.triggerDomainChange!(toPropagate, b)
        @test reified_constraint in toPropagate
    end
end
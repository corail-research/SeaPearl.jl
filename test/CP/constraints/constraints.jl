
@testset "constraints" begin
    include("equal.jl")
    include("notequal.jl")
    include("lessorequal.jl")
    include("greaterorequal.jl")
    include("sumtozero.jl")
    include("sumlessthan.jl")
    include("sumgreaterthan.jl")
    include("islessorequal.jl")
    include("inset.jl")

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

        s = SeaPearl.IntSetVar(2, 6, "x", trailer)
        set_constraint = SeaPearl.InSet(ax, s, trailer)
        SeaPearl.addOnDomainChange!(s, constraint)
        SeaPearl.addOnDomainChange!(ax, constraint)

        @test set_constraint in s.onDomainChange
        @test set_constraint in x.onDomainChange
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

        s = SeaPearl.IntSetVar(2, 6, "x", trailer)
        set_constraint = SeaPearl.InSet(ax, s, trailer)
        SeaPearl.addToPropagate!(toPropagate, constraint)

        @test set_constraint in toPropagate
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

        s = SeaPearl.IntSetVar(2, 6, "x", trailer)
        set_constraint = SeaPearl.InSet(ax, s, trailer)
        SeaPearl.triggerDomainChange!(toPropagate, s)

        @test set_constraint in toPropagate
    end
end
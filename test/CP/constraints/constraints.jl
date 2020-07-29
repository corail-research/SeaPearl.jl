
@testset "constraints" begin
    include("equal.jl")
    include("notequal.jl")
    include("lessorequal.jl")
    include("greaterorequal.jl")
    include("sumtozero.jl")
    include("sumlessthan.jl")
    include("sumgreaterthan.jl")

    @testset "addOnDomainChange!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        ax = SeaPearl.IntVarViewMul(x, 3, "ax")

        constraint = SeaPearl.EqualConstant(ax, 6, trailer)

        SeaPearl.addOnDomainChange!(ax, constraint)

        @test constraint in x.onDomainChange
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

        constraint = SeaPearl.EqualConstant(ax, 6, trailer)

        toPropagate = Set{SeaPearl.Constraint}()


        SeaPearl.triggerDomainChange!(toPropagate, ax)

        @test constraint in toPropagate
    end
end
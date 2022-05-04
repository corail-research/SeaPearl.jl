@testset "rb.jl" begin
    @testset "fill_with_generator!(::RBGenerator)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        k = 3 # arity of each constraint
        n = 5 # number of variables
        α = 1 # determines the domain size d = n^α of each variable,
        r = 2 # determines the number m = r ⋅ n ⋅ ln(n) of constraints,
        p = 0.5 # determines the number t = p ⋅ d^k of disallowed tuples of each relation.
        generator = SeaPearl.RBGenerator(k, n, α, r, p)

        nb::Int64 = round((1 - p) * round(n^α)^k)

        SeaPearl.fill_with_generator!(model, generator)

        @test length(keys(model.variables)) == n
        @test length(model.constraints) == round(r * n * log(n))
        for constraint in model.constraints
            @test isa(constraint, SeaPearl.TableConstraint)
            @test length(constraint.scope) == k
            @test size(constraint.table) == (k, nb)
        end
    end
end
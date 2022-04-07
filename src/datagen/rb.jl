using StatsBase

"""
    struct RBGenerator <: AbstractModelGenerator
    
Details of the problem generator can be found in the article "Random constraint 
satisfaction: Easy generation of hard (satisfiable) instances" (Xu et al., 2007).

Generator of RB instances : 
- k ≥ 2 arity of each constraint
- n ≥ 2 number of variables
- α > 0 determines the domain size d = n^α of each variable,
- r > 0 determines the number m = r ⋅ n ⋅ ln(n) of constraints,
- 0 < p < 1 determines the number nb = (1 - p) ⋅ d^k of disallowed tuples of each relation.
- d domain size of each variable
- m number of constraints
- nb number of allowed tuples of each relation
"""
struct RBGenerator <: AbstractModelGenerator
    k::Int64 # arity of each constraint
    n::Int64 # number of variables
    α::Float64 # determines the domain size d = n^α of each variable,
    r::Float64 # determines the number m = r ⋅ n ⋅ ln(n) of constraints,
    p::Float64 # determines the number t = p ⋅ d^k of disallowed tuples of each relation.
    d::Int64 # domain size of each variable
    m::Int64 # number of constraints
    nb::Int64 # number of allowed tuples of each relation : (1 - p) ⋅ d^k

    function RBGenerator(k, n, α, r, p)
        @assert k >= 2
        @assert n >= 2
        @assert α > 0
        @assert r > 0
        @assert 0 < p && p < 1
        new(k, n, α, r, p, round(n^α), round(r*n*log(n)), round((1 - p) * round(n^α)^k))
    end
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::RBGenerator)   

Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose !

This is the algorithm proposed by "Random constraint satisfaction: Easy generation of 
hard (satisfiable) instances" (Xu. et al, 2007) to generate forced satisfiable instance of RB.
"""
function fill_with_generator!(cpmodel::CPModel, gen::RBGenerator; seed=nothing)
    if !isnothing(seed)
        Random.seed!(seed)
    end
    
    random_solution = rand(1:gen.d, gen.n)

    # create variables
    x = SeaPearl.IntVar[]
    for i in 1:gen.n
        push!(x, SeaPearl.IntVar(1, gen.d, string(i), cpmodel.trailer))
        addVariable!(cpmodel, last(x))
    end
    
    # add constraints
    for i in 1:gen.m
        scope = StatsBase.sample(1:gen.n, gen.k, replace=false, ordered=false)
        variables = [x[j] for j in scope]
        table = zeros(Int64, gen.k, gen.nb)
        table[:, 1] = [random_solution[j] for j in scope]

        tuples = collect(Iterators.product([1:gen.d for j in 1:gen.k]...))
        tuples = reshape(tuples, prod(size(tuples)))
        tuples = [collect(tuple) for tuple in tuples]

        deleteat!(tuples, findfirst(t -> t == table[:, 1], tuples))
        allowed_tuples = StatsBase.sample(tuples, gen.nb-1)

        for (i, tuple) in enumerate(allowed_tuples)
            table[:, i + 1] = tuple
        end

        SeaPearl.addConstraint!(cpmodel, SeaPearl.TableConstraint(variables, table, cpmodel.trailer))
    end

    return nothing
end

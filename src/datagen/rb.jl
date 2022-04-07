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
- 0 < p < 1 determines the number t = p ⋅ d^k of disallowed tuples of each relation.
- d domain size of each variable
- m number of constraints
- t number of disallowed tuples of each relation
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
        new(n, k, α, r, p, round(n^α), round(r*n*log(n)), round((1 - p) * d^k))
    end
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::RBGenerator)   

Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose !

The code below is largely inspired by https://github.com/songwenas12/csp-drl/blob/main/csp_DRL/RBGenerator.py.
"""
function fill_with_generator!(cpmodel::CPModel, gen::RBGenerator; seed=nothing)
    if !isnothing(seed)
        Random.seed!(seed)
    end
    
    random_solution = rand(1:gen.d, gen.n)

    # create variables
    x = SeaPearl.IntVar[]
    for i in 1:n
        push!(x, SeaPearl.IntVar(1, n, string(i), cpmodel.trailer))
        addVariable!(cpmodel, last(x))
    end
    
    # add constraints
    for i in 1:gen.m
        scope = StatsBase.sample(1:gen.n, gen.k, replace=false, ordered=false)
        support = [[random_solution[j]] for j in scope]

        all_tuples = collect(Iterators.product([1:d for j in 1:k]...))
    end


    for i in 1:n
        for j in 1:n
            if i != j && assigned_colors[i] != assigned_colors[j] && rand() <= p
                SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(x[i], x[j], cpmodel.trailer))
            end
        end
    end

    ### Objective ###
    numberOfColors = SeaPearl.IntVar(1, n, "numberOfColors", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, numberOfColors)
    for var in x
        SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqual(var, numberOfColors, cpmodel.trailer))
    end
    SeaPearl.addObjective!(cpmodel,numberOfColors)

    cpmodel.knownObjective = k 
    nothing
end

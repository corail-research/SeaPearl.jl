struct MaximumIndependentSetGenerator <: AbstractModelGenerator
    n::Int
    k::Int
end

function fill_with_generator!(cpmodel::CPModel, gen::MaximumIndependentSetGenerator;  rng::AbstractRNG = MersenneTwister())
    graph = Graphs.SimpleGraphs.barabasi_albert(gen.n, gen.k, seed=rand(rng, typemin(Int64):typemax(Int64)))

    # create variables
    vars = SeaPearl.IntVar[]
    for v in Graphs.vertices(graph)
        push!(vars, SeaPearl.IntVar(0, 1, "node_" * string(v), cpmodel.trailer))
        addVariable!(cpmodel, last(vars))
    end

    # edge constraints
    for e in Graphs.edges(graph)
        SeaPearl.addConstraint!(cpmodel, SeaPearl.SumLessThan([vars[e.src], vars[e.dst]], 1, cpmodel.trailer))
    end

    ### Objective ### minimize: -sum(x[i])
    objective = SeaPearl.IntVar(-Graphs.nv(graph), 0, "objective", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, objective;branchable=false)
    push!(vars, objective)

    # sum(x[i]) + objective = 0 <=> objective = -sum(x[i]) 
    SeaPearl.addConstraint!(cpmodel, SeaPearl.SumToZero(vars, cpmodel.trailer)) 
    SeaPearl.addObjective!(cpmodel,objective)
    cpmodel.adhocInfo = graph

    nothing
end
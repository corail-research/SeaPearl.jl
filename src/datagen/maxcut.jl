using Graphs

"""MaxCutGenerator <: AbstractModelGenerator
Generator for the max-cut problem: https://en.wikipedia.org/wiki/Maximum_cut
"""
struct MaxCutGenerator <: AbstractModelGenerator
    n::Int
    k::Int
end

function fill_with_generator!(cpmodel::CPModel, gen::MaxCutGenerator; rng::AbstractRNG=MersenneTwister())
    graph = Graphs.SimpleGraphs.barabasi_albert(gen.n, gen.k, seed=rand(rng, typemin(Int64):typemax(Int64)))

    # create node variables
    node_vars = SeaPearl.BoolVar[]
    for v in Graphs.vertices(graph)
        push!(node_vars, SeaPearl.BoolVar("node_" * string(v), cpmodel.trailer))
        SeaPearl.addVariable!(cpmodel, last(node_vars))
    end

    # create edge variable and constraints
    edge_vars = SeaPearl.AbstractIntVar[]
    for e in Graphs.edges(graph)
        push!(edge_vars, SeaPearl.BoolVar("edge_" * string(e.src) * "->" * string(e.dst), cpmodel.trailer))
        SeaPearl.addVariable!(cpmodel, last(edge_vars); branchable=false)
        SeaPearl.addConstraint!(cpmodel, SeaPearl.isBinaryXor(last(edge_vars), node_vars[e.src], node_vars[e.dst], cpmodel.trailer))
    end

    ### Objective ### minimize: -sum(edge_vars[i])
    objective = SeaPearl.IntVar(-Graphs.ne(graph), 0, "objective", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, objective; branchable=false)
    push!(edge_vars, objective)

    # sum(edge_vars[i]) + objective = 0 <=> objective = -sum(edge_vars[i]) 
    SeaPearl.addConstraint!(cpmodel, SeaPearl.SumToZero(edge_vars, cpmodel.trailer))
    SeaPearl.addObjective!(cpmodel, objective)

    cpmodel.adhocInfo = graph
    nothing
end
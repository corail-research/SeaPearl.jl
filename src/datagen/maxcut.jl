using Graphs

struct MaxCutGenerator <: AbstractModelGenerator
    n::Int
    k::Int
end

function fill_with_generator!(cpmodel::CPModel, gen::MaxCutGenerator;  rng::AbstractRNG = MersenneTwister())
    graph = Graphs.SimpleGraphs.barabasi_albert(gen.n, gen.k, seed=rand(rng, typemin(Int64):typemax(Int64)))

    # create node variables
    node_vars = SeaPearl.IntVar[]
    opposite_node_vars = SeaPearl.IntVarViewOpposite[]
    for v in Graphs.vertices(graph)
        push!(node_vars, SeaPearl.IntVar(0, 1, "node_" * string(v), cpmodel.trailer))
        push!(opposite_node_vars, SeaPearl.IntVarViewOpposite(last(node_vars), "-node_" * string(v)))
        SeaPearl.addVariable!(cpmodel, last(node_vars))
    end

    # create edge variable and constraints
    edge_vars = SeaPearl.IntVar[]
    for e in Graphs.edges(graph)
        push!(edge_vars, SeaPearl.IntVar(0, 1, "edge_" * string(e.src) * "->" * string(e.dst), cpmodel.trailer))
        SeaPearl.addVariable!(cpmodel, last(edge_vars); branchable=false)
        # We want e = (e.src != e.dst)
        # Since we can't write it like that in SeaPearl, we use the equivalence
        # e = (e.src != e.dst) <=> (e - e.src - e.dst <= 0 && e + e.src + e.dst <= 2)
        SeaPearl.addConstraint!(cpmodel, SeaPearl.SumLessThan([last(edge_vars), opposite_node_vars[e.src], opposite_node_vars[e.dst]], 0, cpmodel.trailer))
        SeaPearl.addConstraint!(cpmodel, SeaPearl.SumLessThan([last(edge_vars), node_vars[e.src], node_vars[e.dst]], 2, cpmodel.trailer))
    end

    ### Objective ### minimize: -sum(edge_vars[i])
    objective = SeaPearl.IntVar(-Graphs.ne(graph), 0, "objective", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, objective;branchable=false)
    push!(edge_vars, objective)

    # sum(edge_vars[i]) + objective = 0 <=> objective = -sum(edge_vars[i]) 
    SeaPearl.addConstraint!(cpmodel, SeaPearl.SumToZero(edge_vars, cpmodel.trailer)) 
    SeaPearl.addObjective!(cpmodel,objective)

    nothing
end
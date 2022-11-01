struct LegacyGraphColoringGenerator <: AbstractModelGenerator
    nb_nodes::Int
    density::Real
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::GraphColoringGenerator)  
Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose.

This generator create clustered graphs for the graph coloring problem. It is having a fixed number of
nodes and edges which is convenient to have problems of constant size. This is not compulsory (not the case 
of the knapsack and of the homogeneous graph generator) but it is interesting to be sure we're working
on more smooth cases.

This is done by getting a geometric distribution of each node connectivity (number of edges) and then select
randomly the connexions. 
"""
function fill_with_generator!(cpmodel::CPModel, gen::LegacyGraphColoringGenerator; rng::AbstractRNG=MersenneTwister())
    density = gen.density
    nb_nodes = gen.nb_nodes

    nb_edges = floor(Int64, density * nb_nodes)

    # create variables
    x = SeaPearl.IntVar[]
    for i in 1:nb_nodes
        push!(x, SeaPearl.IntVar(1, nb_nodes, string(i), cpmodel.trailer))
        addVariable!(cpmodel, last(x))
    end
    @assert nb_edges >= nb_nodes - 1
    connexions = [1 for i in 1:nb_nodes]
    # create Geometric distribution
    p = 2 / nb_nodes
    distr = Truncated(Geometric(p), 1, nb_nodes)
    new_connexions = rand(rng, distr, nb_edges - nb_nodes)
    for new_co in new_connexions
        connexions[convert(Int64, new_co)] += 1
    end
    # should make sure that every node has less than nb_nodes - 1 connexions
    # edge constraints
    for i in 1:length(connexions)
        possible_neightbors = [j for j in (i+1):length(connexions) if connexions[i] > 0]
        neighbors = Distributions.sample(rng, possible_neightbors, min(connexions[i], length(possible_neightbors)), replace=false)
        for j in neighbors
            SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(x[i], x[j], cpmodel.trailer))
        end
    end

    ### Objective ###
    numberOfColors = SeaPearl.IntVar(1, nb_nodes, "numberOfColors", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, numberOfColors, branchable=false)
    SeaPearl.addConstraint!(cpmodel, SeaPearl.MaximumConstraint(x, numberOfColors, cpmodel.trailer))
    SeaPearl.addObjective!(cpmodel, numberOfColors)
end

struct HomogenousGraphColoringGenerator <: AbstractModelGenerator
    nb_nodes::Int
    probability::Real

    function HomogenousGraphColoringGenerator(n, p)
        @assert n > 0
        @assert 0 < p && p <= 1
        new(n, p)
    end
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::GraphColoringGenerator)::CPModel    

Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose ! Density should be more than 1.

Very simple case from: Exploring the k-colorable Landscape with Iterated Greedy by Culberson & Luo
https://pdfs.semanticscholar.org/e6cc/ab8f757203bf15680dbf456f295a7a31431a.pdf
"""
function fill_with_generator!(cpmodel::CPModel, gen::HomogenousGraphColoringGenerator; rng::AbstractRNG=MersenneTwister())
    p = gen.probability
    n = gen.nb_nodes

    # create variables
    x = SeaPearl.IntVar[]
    for i in 1:n
        push!(x, SeaPearl.IntVar(1, n, string(i), cpmodel.trailer))
        addVariable!(cpmodel, last(x))
    end

    # edge constraints
    for i in 1:n
        for j in (i+1):n
            if rand(rng) <= p
                SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(x[i], x[j], cpmodel.trailer))
            end
        end
    end

    ### Objective ###
    numberOfColors = SeaPearl.IntVar(1, n, "numberOfColors", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, numberOfColors, branchable=false)
    SeaPearl.addConstraint!(cpmodel, SeaPearl.MaximumConstraint(x, numberOfColors, cpmodel.trailer))
    SeaPearl.addObjective!(cpmodel, numberOfColors)
end

"""
    struct ClusterizedGraphColoringGenerator <: AbstractModelGenerator

    Generator of Graph Coloring instances : 
    - n is the number of nodes
    - k is the number of color
    - p is the edge density of the graph
"""
struct ClusterizedGraphColoringGenerator <: AbstractModelGenerator
    n::Int64
    k::Int64
    p::Float64

    function ClusterizedGraphColoringGenerator(n, k, p)
        @assert n > 0
        @assert k > 0 && k <= n
        @assert 0 <= p && p <= 1
        new(n, k, p)
    end
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::GraphColoringGenerator)::CPModel    

Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose ! Density should be more than 1.

Very simple case from: Exploring the k-colorable Landscape with Iterated Greedy by Culberson & Luo
https://pdfs.semanticscholar.org/e6cc/ab8f757203bf15680dbf456f295a7a31431a.pdf
"""
function fill_with_generator!(cpmodel::CPModel, gen::ClusterizedGraphColoringGenerator; rng::AbstractRNG=MersenneTwister())
    n = gen.n
    p = gen.p
    k = gen.k

    assigned_colors = zeros(Int64, gen.n)
    for i in 1:n
        assigned_colors[i] = rand(rng, 1:k)
    end

    # create variables
    x = SeaPearl.IntVar[]
    for i in 1:n
        push!(x, SeaPearl.IntVar(1, n, string(i), cpmodel.trailer))
        addVariable!(cpmodel, last(x))
    end

    # edge constraints
    for i in 1:n
        for j in (i+1):n
            if assigned_colors[i] != assigned_colors[j] && rand(rng) <= p
                SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(x[i], x[j], cpmodel.trailer))
            end
        end
    end

    ### Objective ###
    numberOfColors = SeaPearl.IntVar(1, n, "numberOfColors", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, numberOfColors, branchable=false)
    SeaPearl.addConstraint!(cpmodel, SeaPearl.MaximumConstraint(x, numberOfColors, cpmodel.trailer))
    SeaPearl.addObjective!(cpmodel, numberOfColors)
    cpmodel.knownObjective = k 
end

"""
    struct BarabasiAlbertGraphGenerator <: AbstractModelGenerator

    Generator of Graph Coloring instances : 
    - n is the number of nodes
    - k is the number of color
    http://networksciencebook.com/chapter/5
"""
struct BarabasiAlbertGraphGenerator <: AbstractModelGenerator
    n::Int64
    k::Int64
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::BarabasiAlbertGraphGenerator)::CPModel
    Creates graphs according to the Barbarasi-Albert attachment model: http://networksciencebook.com/chapter/5
"""
function fill_with_generator!(cpmodel::CPModel, gen::BarabasiAlbertGraphGenerator; rng::AbstractRNG=MersenneTwister())
    graph = Graphs.SimpleGraphs.barabasi_albert(gen.n, gen.k, seed=rand(rng, typemin(Int64):typemax(Int64)))

    # create variables
    vars = SeaPearl.IntVar[]
    for v in Graphs.vertices(graph)
        push!(vars, SeaPearl.IntVar(1, gen.n, "node_" * string(v), cpmodel.trailer))
        addVariable!(cpmodel, last(vars))
    end
    # edge constraints
    for e in Graphs.edges(graph)
        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(vars[e.src], vars[e.dst], cpmodel.trailer))
    end

    ### Objective ###
    numberOfColors = SeaPearl.IntVar(1, gen.n, "numberOfColors", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, numberOfColors, branchable=false)
    SeaPearl.addConstraint!(cpmodel, SeaPearl.MaximumConstraint(vars, numberOfColors, cpmodel.trailer))
    SeaPearl.addObjective!(cpmodel, numberOfColors)
    cpmodel.adhocInfo = graph
end
"""
    struct ErdosRenyiGraphGenerator <: AbstractModelGenerator

    Generator of Graph Coloring instances : 
    - n is the number of nodes
    - k is the number of color

    https://en.wikipedia.org/wiki/Erd%C5%91s%E2%80%93R%C3%A9nyi_model
"""
struct ErdosRenyiGraphGenerator <: AbstractModelGenerator
    n::Int64
    p::Float64
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::ErdosRenyiGraphGenerator)::CPModel    

    Generates graphs according to the Erdos-Renyi model: https://en.wikipedia.org/wiki/Erd%C5%91s%E2%80%93R%C3%A9nyi_model
"""
function fill_with_generator!(cpmodel::CPModel, gen::ErdosRenyiGraphGenerator; rng::AbstractRNG=MersenneTwister())
    graph = Graphs.SimpleGraphs.erdos_renyi(gen.n, gen.p, seed=rand(rng, typemin(Int64):typemax(Int64)))

    # create variables
    vars = SeaPearl.IntVar[]
    for v in Graphs.vertices(graph)
        push!(vars, SeaPearl.IntVar(1, gen.n, "node_" * string(v), cpmodel.trailer))
        addVariable!(cpmodel, last(vars))
    end
    # edge constraints
    for e in Graphs.edges(graph)
        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(vars[e.src], vars[e.dst], cpmodel.trailer))
    end

    ### Objective ###
    numberOfColors = SeaPearl.IntVar(1, gen.n, "numberOfColors", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, numberOfColors, branchable=false)
    SeaPearl.addConstraint!(cpmodel, SeaPearl.MaximumConstraint(vars, numberOfColors, cpmodel.trailer))
    SeaPearl.addObjective!(cpmodel, numberOfColors)
    cpmodel.adhocInfo = graph
end

struct WattsStrogatzGraphGenerator <: AbstractModelGenerator
    n::Int64
    k::Int64
    beta::Float32
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::WattsStrogatzGraphGenerator)::CPModel    
"""
function fill_with_generator!(cpmodel::CPModel, gen::WattsStrogatzGraphGenerator; rng::AbstractRNG=MersenneTwister())
    graph = Graphs.SimpleGraphs.watts_strogatz(gen.n, gen.k, gen.beta, seed=rand(rng, typemin(Int64):typemax(Int64)))

    # create variables
    vars = SeaPearl.IntVar[]
    for v in Graphs.vertices(graph)
        push!(vars, SeaPearl.IntVar(1, gen.n, "node_" * string(v), cpmodel.trailer))
        addVariable!(cpmodel, last(vars))
    end
    # edge constraints
    for e in Graphs.edges(graph)
        SeaPearl.addConstraint!(cpmodel, SeaPearl.NotEqual(vars[e.src], vars[e.dst], cpmodel.trailer))
    end

    ### Objective ###
    numberOfColors = SeaPearl.IntVar(1, gen.n, "numberOfColors", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, numberOfColors, branchable=false)
    SeaPearl.addConstraint!(cpmodel, SeaPearl.MaximumConstraint(vars, numberOfColors, cpmodel.trailer))
    SeaPearl.addObjective!(cpmodel, numberOfColors)
    cpmodel.adhocInfo = graph
end
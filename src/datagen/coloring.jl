using Distributions

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
function fill_with_generator!(cpmodel::CPModel, gen::LegacyGraphColoringGenerator; rng=nothing)
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
    distr = Truncated(Geometric(p), 0, nb_nodes)
    new_connexions = rand(distr, nb_edges - nb_nodes)
    for new_co in new_connexions
        connexions[convert(Int64, new_co)] += 1
    end

    # should make sure that every node has less than nb_nodes - 1 connexions

    # edge constraints
    for i in 1:length(connexions)
        neighbors = sample([j for j in 1:length(connexions) if j != i && connexions[i] > 0], connexions[i], replace=false)
        for j in neighbors
            push!(cpmodel.constraints, SeaPearl.NotEqual(x[i], x[j], cpmodel.trailer))
        end
    end

    ### Objective ###
    numberOfColors = SeaPearl.IntVar(1, nb_nodes, "numberOfColors", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, numberOfColors)
    for var in x
        push!(cpmodel.constraints, SeaPearl.LessOrEqual(var, numberOfColors, cpmodel.trailer))
    end
    cpmodel.objective = numberOfColors

    nothing
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
function fill_with_generator!(cpmodel::CPModel, gen::HomogenousGraphColoringGenerator; rng=nothing)
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
        for j in 1:n
            if isnothing(rng)
                if i != j && rand() <= p
                    push!(cpmodel.constraints, SeaPearl.NotEqual(x[i], x[j], cpmodel.trailer))
                end
            else
                if i != j && rand(rng) <= p
                    push!(cpmodel.constraints, SeaPearl.NotEqual(x[i], x[j], cpmodel.trailer))
                end
            end
        end
    end

    ### Objective ###
    numberOfColors = SeaPearl.IntVar(1, n, "numberOfColors", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, numberOfColors)
    for var in x
        push!(cpmodel.constraints, SeaPearl.LessOrEqual(var, numberOfColors, cpmodel.trailer))
    end
    cpmodel.objective = numberOfColors

    nothing
end

struct GraphColoringWithFileGenerator <: AbstractModelGenerator
    input_file::String
end

struct Edge
    vertex1     :: Int
    vertex2     :: Int
end

struct InputData
    edges               :: Array{Edge}
    numberOfEdges       :: Int
    numberOfVertices    :: Int
end

struct OutputData
    numberOfColors      :: Int
    edgeColors          :: Array{Int}
    optimality          :: Bool
end

include("IOmanager.jl")

function fill_with_generator!(model::CPModel, gen::GraphColoringWithFileGenerator; rng=nothing)
    input_file = gen.input_file
    input = getInputData(input_file)

    trailer = model.trailer

    ### Variable declaration ###
    x = SeaPearl.IntVar[]
    for i in 1:input.numberOfVertices
        push!(x, SeaPearl.IntVar(1, input.numberOfVertices, string(i), trailer))
        SeaPearl.addVariable!(model, last(x))
    end

    ### Constraints ###
    # Breaking some symmetries
    push!(model.constraints, SeaPearl.EqualConstant(x[1], 1, trailer))
    push!(model.constraints, SeaPearl.LessOrEqual(x[1], x[2], trailer))

    # Edge constraints
    degrees = zeros(Int, input.numberOfVertices)
    for e in input.edges
        push!(model.constraints, SeaPearl.NotEqual(x[e.vertex1], x[e.vertex2], trailer))
        degrees[e.vertex1] += 1
        degrees[e.vertex2] += 1
    end
    sortedPermutation = sortperm(degrees; rev=true)

    ### Objective ###
    numberOfColors = SeaPearl.IntVar(1, input.numberOfVertices, "numberOfColors", trailer)
    SeaPearl.addVariable!(model, numberOfColors)
    for var in x
        push!(model.constraints, SeaPearl.LessOrEqual(var, numberOfColors, trailer))
    end
    model.objective = numberOfColors


    ### Variable selection heuristic ###
    function selectVariable(model::SeaPearl.CPModel, sortedPermutation, degrees)
        maxDegree = 0
        toReturn = nothing
        for i in sortedPermutation
            if !SeaPearl.isbound(model.variables[string(i)])
                if isnothing(toReturn)
                    toReturn = model.variables[string(i)]
                    maxDegree = degrees[i]
                end
                if degrees[i] < maxDegree
                    return toReturn
                end

                if length(model.variables[string(i)].domain) < length(toReturn.domain)
                    toReturn = model.variables[string(i)]
                end
            end
        end
        return toReturn
    end

    return ((m) -> selectVariable(m, sortedPermutation, degrees))
end

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
function fill_with_generator!(cpmodel::CPModel, gen::ClusterizedGraphColoringGenerator; seed=nothing)
    if !isnothing(seed)
        Random.seed!(seed)
    end
    
    n = gen.n
    p = gen.p
    k = gen.k
    
    assigned_colors = zeros(Int64, gen.n)
    for i in 1:n
        assigned_colors[i] = rand(1:k)
    end

    # create variables
    x = SeaPearl.IntVar[]
    for i in 1:n
        push!(x, SeaPearl.IntVar(1, n, string(i), cpmodel.trailer))
        addVariable!(cpmodel, last(x))
    end
    
    # edge constraints
    for i in 1:n
        for j in 1:n
            if i != j && assigned_colors[i] != assigned_colors[j] && rand() <= p
                push!(cpmodel.constraints, SeaPearl.NotEqual(x[i], x[j], cpmodel.trailer))
            end
        end
    end

    ### Objective ###
    numberOfColors = SeaPearl.IntVar(1, n, "numberOfColors", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, numberOfColors)
    for var in x
        push!(cpmodel.constraints, SeaPearl.LessOrEqual(var, numberOfColors, cpmodel.trailer))
    end
    cpmodel.objective = numberOfColors

    nothing
end
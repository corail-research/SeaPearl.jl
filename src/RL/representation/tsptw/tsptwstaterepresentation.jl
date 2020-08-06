
struct TsptwFeaturization <: AbstractFeaturization end

"""
    TsptwStateRepresentation{F}

This is the Tsptw representation used by Quentin Cappart in Combining Reinforcement Learning and Constraint Programming
for Combinatorial Optimization (https://arxiv.org/pdf/2006.01610.pdf).
"""
mutable struct TsptwStateRepresentation{F} <: FeaturizedStateRepresentation{F}
    citiesgraph::SimpleWeightedGraphs.SimpleWeightedGraph
    features::Union{Nothing, Array{Float32, 2}}
    variable_id::Union{Nothing, Int64}
    possible_value_ids::Union{Nothing, Array{Int64}}
end

function TsptwStateRepresentation{F}(model::CPModel) where F
    ### build citiesgraph
    # get the distance matrix from Element2D constraint 
    cstr = filter(x -> typeof(x) == Element2D, model.constraint)
    dist = cstr[1].matrix
    citiesgraph = SimpleWeightedGraphs.SimpleWeightedGraph(dist)

    sr = TsptwStateRepresentation{F}(citiesgraph, nothing, nothing, nothing)

    features = featurize(sr)
    sr.features = transpose(features)
    sr
end

TsptwStateRepresentation(m::CPModel) = TsptwStateRepresentation{TsptwFeaturization}(m::CPModel)

function update_representation!(sr::TsptwStateRepresentation, model::CPModel, x::AbstractIntVar)
    sr.variable_id = indexFromCpVertex(sr.cplayergraph, VariableVertex(x))
    sr.possible_value_ids = possible_values(sr.variable_id, sr.cplayergraph)
    sr
end

function to_arraybuffer(sr::TsptwStateRepresentation, rows=nothing::Union{Nothing, Int})::Array{Float32, 2}
    adj = Matrix(LightGraphs.LinAlg.adjacency_matrix(sr.cplayergraph))
    var_id = sr.variable_id

    var_code = zeros(Float32, size(adj, 1))
    var_code[var_id] = 1f0

    vector_values = zeros(Float32, size(adj, 1))
    for i in sr.possible_value_ids
        vector_values[i] = 1.
    end

    
    if isnothing(rows)
        return hcat(ones(Float32, size(adj, 1), 1), adj, transpose(sr.features), var_code, vector_values)
    end

    @assert rows > size(adj, 1) "maxNumberOfCPNodes too small"

    cp_graph_array = hcat(ones(Float32, size(adj, 1), 1), adj, zeros(Float32, size(adj, 1), rows - size(adj, 1)), transpose(sr.features), var_code, vector_values)
    filler = zeros(Float32, rows - size(cp_graph_array, 1), size(cp_graph_array, 2))

    return vcat(cp_graph_array, filler)
end

function featuredgraph(array::Array{Float32, 2})::GeometricFlux.FeaturedGraph
    # Here we only take what's interesting, removing all null values that are there only to accept bigger graphs
    row_indexes = findall(x -> x == 1, array[:, 1])
    col_indexes = vcat(1 .+ row_indexes, (size(array, 1)+2):size(array, 2))
    array = view(array, row_indexes, col_indexes)
    
    n = size(array, 1)
    dense_adj = array[:, 1:n]
    features = array[:, n+1:end-2]

    return GeometricFlux.FeaturedGraph(dense_adj, transpose(features))
end

function branchingvariable_id(array::Array{Float32, 2})::Int64
    findfirst(x -> x == 1, array[:, end-1])
end


"""
    function featurize(sr::TsptwStateRepresentation{TsptwFeaturization})

Create features for every node of the graph. Supposed to be overwritten. 
Tsptw behavior is to call `Tsptw_featurize`.
"""
function featurize(sr::TsptwStateRepresentation{TsptwFeaturization})
    g = sr.cplayergraph
    features = zeros(Float32, nv(g), 3)
    for i in 1:nv(g)
        cp_vertex = SeaPearl.cpVertexFromIndex(g, i)
        if isa(cp_vertex, ConstraintVertex)
            features[i, 1] = 1.0f0
        end
        if isa(cp_vertex, VariableVertex)
            features[i, 2] = 1.0f0
        end
        if isa(cp_vertex, ValueVertex)
            features[i, 3] = 1.0f0
        end
    end
    features
end

"""
    function possible_values(variable_id::Int64, g::CPLayerGraph)

Return the ids of the values that the variable denoted by `variable_id` can take.
It actually returns the id of every ValueVertex neighbors of the VariableVertex.

"""
function possible_values(variable_id::Int64, g::CPLayerGraph)
    possible_values = LightGraphs.neighbors(g, variable_id)
    filter!((id) -> isa(cpVertexFromIndex(g, convert(Int64, id)), ValueVertex), possible_values)
    return possible_values
end

"""
    function possible_value_ids(array::Array{Float32, 2})

Returns the ids of the ValueVertex that are in the domain of the variable we are branching on.
"""
function possible_value_ids(array::Array{Float32, 2})
    findall(x -> x == 1, array[:, end])
end
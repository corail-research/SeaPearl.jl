using SimpleWeightedGraphs


struct TsptwFeaturization <: AbstractFeaturization end

"""
    TsptwStateRepresentation{F}

This is the Tsptw representation used by Quentin Cappart in Combining Reinforcement Learning and Constraint Programming
for Combinatorial Optimization (https://arxiv.org/pdf/2006.01610.pdf).
"""
mutable struct TsptwStateRepresentation{F} <: FeaturizedStateRepresentation{F}
    dist::Matrix
    time_windows::Matrix
    pos::Matrix
    citiesgraph::SimpleWeightedGraphs.SimpleWeightedGraph
    features::Union{Nothing, Array{Float32, 2}}
    current_city::Union{Nothing, Int64}
    possible_value_ids::Union{Nothing, Array{Int64}}
end

function TsptwStateRepresentation{F}(model::CPModel) where F
    ### build citiesgraph
    dist, time_windows, pos = get_tsptw_info(model)
    citiesgraph = SimpleWeightedGraphs.SimpleWeightedGraph(dist)

    sr = TsptwStateRepresentation{F}(dist, time_windows, pos, citiesgraph, nothing, nothing, nothing)

    sr.features = featurize(sr)
    sr
end

TsptwStateRepresentation(model::CPModel) = TsptwStateRepresentation{TsptwFeaturization}(model)

function get_tsptw_info(model::CPModel)
    dist, time_windows, pos, grid_size = model.adhocInfo

    max_d = Base.maximum(dist)
    max_tw = Base.maximum(time_windows)

    dist = dist ./ max_d
    time_windows = time_windows ./ max_tw
    pos = pos ./ grid_size

    return dist, time_windows, pos
end

function update_representation!(sr::TsptwStateRepresentation, model::CPModel, x::AbstractIntVar)
    sr.possible_value_ids = collect(x.domain)

    i = 1
    while x.id != "a_"*string(i)
        i += 1
    end
    if SeaPearl.isbound(model.variables["v_"*string(i)])
        sr.current_city = SeaPearl.assignedValue(model.variables["v_"*string(i)])
    end
    sr.features = featurize(sr)
    sr
end

function to_arraybuffer(sr::TsptwStateRepresentation, rows=nothing::Union{Nothing, Int})::Array{Float32, 2}
    dist = sr.dist

    vector_values = zeros(Float32, size(dist, 1))
    if !isnothing(sr.possible_value_ids)
        for i in sr.possible_value_ids
            vector_values[i] = 1.
        end
    end
    vector_current = zeros(Float32, size(dist, 1))
    if !isnothing(sr.current_city)
        vector_current[sr.current_city] = 1.
    end

    return hcat(sr.dist, sr.features, vector_current, vector_values)
end

function featuredgraph(array::Array{Float32, 2}, ::Type{TsptwStateRepresentation})::GeometricFlux.FeaturedGraph    
    n = size(array, 1)
    dense_adj = array[:, 1:n]
    features = array[:, n+1:end-2]

    adj = round.(dense_adj) # Does not support weighted edges

    return GraphSignals.FeaturedGraph(adj; nf=permutedims(features, [2, 1]))
end

function branchingvariable_id(array::Array{Float32, 2}, ::Type{TsptwStateRepresentation})::Int64
    findfirst(x -> x == 1, array[:, end-1])
end


"""
    function featurize(sr::TsptwStateRepresentation{TsptwFeaturization})

Create features for every node of the graph. Supposed to be overwritten. 
Tsptw behavior is to call `Tsptw_featurize`.
"""
function featurize(sr::TsptwStateRepresentation{TsptwFeaturization})
    n = size(sr.dist, 1)
    features = zeros(Float32, n, 6)
    for i in 1:n
        if !isnothing(sr.possible_value_ids) && !(i in sr.possible_value_ids)
            features[i , 5] = 1.
        end
        if i == sr.current_city
            features[i, 6] = 1.
        end
    end

    features[:, 1:2] = sr.pos
    features[:, 3:4] = sr.time_windows
    features
end

"""
    function possible_value_ids(array::Array{Float32, 2})

Returns the ids of the ValueVertex that are in the domain of the variable we are branching on.
"""
function possible_value_ids(array::Array{Float32, 2}, ::Type{TsptwStateRepresentation})
    findall(x -> x == 1, array[:, end])
end
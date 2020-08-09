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
    citiesgraph::SimpleWeightedGraphs.SimpleWeightedGraph
    features::Union{Nothing, Array{Float32, 2}}
    current_city::Union{Nothing, Int64}
    possible_value_ids::Union{Nothing, Array{Int64}}
end

function TsptwStateRepresentation{F}(model::CPModel) where F
    ### build citiesgraph
    dist, time_windows = get_dist_and_tw(model)
    citiesgraph = SimpleWeightedGraphs.SimpleWeightedGraph(dist)

    sr = TsptwStateRepresentation{F}(dist, time_windpws, citiesgraph, nothing, nothing, nothing)

    features = featurize(sr)
    sr.features = transpose(features)
    sr
end

TsptwStateRepresentation(model::CPModel) = TsptwStateRepresentation{TsptwFeaturization}(model)

function get_dist_and_tw(model::CPModel)
    dist = nothing
    tw_up = nothing
    tw_low = nothing
    for constraint in model.constraints
        if isnothing(dist) && isa(constraint, SeaPearl.Element2D) && size(constraint.matrix, 2) > 1
            dist = constraint.matrix
        end
        if isnothing(tw_low) && isa(constraint, SeaPearl.Element2D) && constraint.z.id == "lower_ai_1"
            tw_low = constraint.matrix
        end
        if isnothing(tw_up) && isa(constraint, SeaPearl.Element2D) && constraint.z.id == "upper_ai_1"
            tw_up = constraint.matrix
        end
    end

    max_d = maximum(dist)
    max_low = maximum(tw_low)
    max_up = maximum(tw_up)
    max_all = max(max_d, max_low, max_up)

    dist = dist ./ max_all
    tw_low = tw_low ./ max_all
    tw_up = tw_up ./ max_all

    return dist, hcat(tw_low, tw_up)
end

TsptwStateRepresentation(m::CPModel) = TsptwStateRepresentation{TsptwFeaturization}(m::CPModel)

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
    for i in sr.possible_value_ids
        vector_values[i] = 1.
    end
    vector_current = zeros(Float32, size(dist, 1))
    if !isnothing(sr.current_city)
        vector_current[sr.current_city] = 1.
    end
    
    return hcat(sr.dist, sr.features, vector_values, vector_current)
end

function featuredgraph(array::Array{Float32, 2})::GeometricFlux.FeaturedGraph    
    n = size(array, 1)
    dense_adj = array[:, 1:n]
    features = array[:, n+1:end-2]

    return GeometricFlux.FeaturedGraph(dense_adj, transpose(features))
end

function branchingvariable_id(array::Array{Float32, 2})::Int64
    findfirst(x -> x == 1, array[:, end])
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
        features[i, 1] = 0.
        features[i, 2] = 0.
        if !(i in sr.possible_value_ids)
            features[i , 5] = 1.
        end
        if i == sr.current_city
            features[i, 6] = 1.
        end
    end

    features[:, 3:4] = sr.time_windows
    features
end

"""
    function possible_value_ids(array::Array{Float32, 2})

Returns the ids of the ValueVertex that are in the domain of the variable we are branching on.
"""
function possible_value_ids(array::Array{Float32, 2})
    findall(x -> x == 1, array[:, end-1])
end
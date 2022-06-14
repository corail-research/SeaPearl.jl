"""
BatchedHeterogeneousFeaturedGraph

A batched representation of the HeterogeneousFeaturedGraph, to enable parallel computation.

It is deliberately more restrictive to prevent incorrect usage.
"""
struct BatchedHeterogeneousFeaturedGraph{T <: Real} <: AbstractFeaturedGraph
    contovar::AbstractArray{T, 3}
    valtovar::AbstractArray{T, 3}
    varnf::AbstractArray{T, 3}
    connf::AbstractArray{T, 3}
    valnf::AbstractArray{T, 3}
    gf::AbstractMatrix{T}

    function BatchedHeterogeneousFeaturedGraph{T}(contovar, valtovar, varnf, connf, valnf, gf) where T <: Real
        check_dimensions(contovar, valtovar, varnf, connf, valnf, gf)
        return new{T}(contovar, valtovar, varnf, connf, valnf, gf)
    end
end

BatchedHeterogeneousFeaturedGraph(contovar, valtovar, varnf, connf, valnf, gf) = BatchedHeterogeneousFeaturedGraph{Float32}(contovar, valtovar, varnf, connf, valnf, gf)

function BatchedHeterogeneousFeaturedGraph{T}(fgs::Vector{FG}) where {T <: Real, FG <: HeterogeneousFeaturedGraph}
    ngraphs = length(fgs)
    maxNumberOfConstraintNodes = Base.maximum(n_constraint_node, fgs)
    maxNumberOfVariableNodes = Base.maximum(n_variable_node, fgs)
    maxNumberOfValueNodes = Base.maximum(n_value_node, fgs)
    varnfLength = size(fgs[1].varnf, 1) # size of the feature vector for the variable nodes.
    connfLength = size(fgs[1].connf, 1) # size of the feature vector for the constraint nodes.
    valnfLength = size(fgs[1].valnf, 1) # size of the feature vector for the value nodes.
    gfLength = size(fgs[1].gf, 1) # size of the feature vector for the graph.

    contovar = zeros(T, maxNumberOfConstraintNodes, maxNumberOfVariableNodes, ngraphs)
    valtovar = zeros(T, maxNumberOfValueNodes, maxNumberOfVariableNodes, ngraphs)
    varnf = zeros(T, varnfLength, maxNumberOfVariableNodes, ngraphs)
    connf = zeros(T, connfLength, maxNumberOfConstraintNodes, ngraphs)
    valnf = zeros(T, valnfLength, maxNumberOfValueNodes, ngraphs)
    gf = zeros(T, gfLength, ngraphs)

    for (i, fg) in enumerate(fgs)
        contovar[1:n_constraint_node(fg),1:n_variable_node(fg),i] = fg.contovar
        valtovar[1:n_value_node(fg),1:n_variable_node(fg),i] = fg.valtovar
        varnf[:, 1:n_variable_node(fg), i] = fg.varnf
        connf[:, 1:n_constraint_node(fg), i] = fg.connf
        valnf[:, 1:n_value_node(fg), i] = fg.valnf
        gf[:, i] = fg.gf
    end

    return BatchedHeterogeneousFeaturedGraph{T}(contovar, valtovar, varnf, connf, valnf, gf)
end

BatchedHeterogeneousFeaturedGraph(fgs::Vector{FG}) where {FG <: HeterogeneousFeaturedGraph} = BatchedHeterogeneousFeaturedGraph{Float32}(fgs)

# ========== Accessing ==========

"""
    variable_node_feature(::HeterogeneousFeaturedGraph)
Return the variable nodes features matrix of the graph.
"""
variable_node_feature(fg::BatchedHeterogeneousFeaturedGraph{T}) where {T} = fg.varnf

"""
    constraint_node_feature(::HeterogeneousFeaturedGraph)
Return the constraint nodes features matrix of the batch of graph.
"""
constraint_node_feature(fg::BatchedHeterogeneousFeaturedGraph{T}) where {T} = fg.connf

"""
    value_node_feature(::HeterogeneousFeaturedGraph)
Return the value nodes features matrix of the batch of graph.
"""
value_node_feature(fg::BatchedHeterogeneousFeaturedGraph{T}) where {T} = fg.valnf

"""
    n_variable_node(::HeterogeneousFeaturedGraph)
Return the number of variable nodes of the batch of graph.
"""
n_variable_node(fg::BatchedHeterogeneousFeaturedGraph{T}) where {T} = map(v -> size(fg.varnf[:,:,v],2), axes(fg.varnf, 3))
#could be replace with size(fg.varnf[:,:,1],2)

"""
    n_constraint_node(::HeterogeneousFeaturedGraph)
Return the number of constraint nodes of the batch of graph.
"""
n_constraint_node(fg::BatchedHeterogeneousFeaturedGraph{T}) where {T} = map(v -> size(fg.connf[:,:,v],2), axes(fg.connf, 3))
#could be replace with size(fg.connf[:,:,1],2)
"""
    n_value_node(::HeterogeneousFeaturedGraph)
Return the number of value nodes of the batch of graph.
"""
n_value_node(fg::BatchedHeterogeneousFeaturedGraph{T}) where {T} = map(v -> size(fg.valnf[:,:,v],2), axes(fg.valnf, 3))
#could be replace with size(fg.valnf[:,:,1],2)

"""
    global_feature(::HeterogeneousFeaturedGraph)
Return the global feature vector of the batch of graph.
"""
global_feature(fg::BatchedHeterogeneousFeaturedGraph{T}) where {T}  = fg.gf
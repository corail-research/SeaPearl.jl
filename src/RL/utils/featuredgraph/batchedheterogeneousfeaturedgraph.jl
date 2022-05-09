"""
BatchedHeterogeneousFeaturedGraph

A batched representation of the HeterogeneousFeaturedGraph, to enable parallel computation.

It is deliberately more restrictive to prevent incorrect usage.
"""
struct BatchedHeterogeneousFeaturedGraph{T <: Real} <: AbstractFeaturedGraph
    contovar::AbstractArray{T, 3}
    valtovar::AbstractArray{T, 3}
    connf::AbstractArray{T, 3}
    varnf::AbstractArray{T, 3}
    valnf::AbstractArray{T, 3}
    gf::AbstractMatrix{T}

    function BatchedHeterogeneousFeaturedGraph{T}(contovar, valtovar, connf, varnf, valnf, gf) where T <: Real
        check_dimensions(contovar, valtovar, connf, varnf, valnf, gf)
        return new{T}(contovar, valtovar, connf, varnf, valnf, gf)
    end
end

BatchedHeterogeneousFeaturedGraph(contovar, valtovar, connf, varnf, valnf, gf) = BatchedHeterogeneousFeaturedGraph{Float32}(contovar, valtovar, connf, varnf, valnf, gf)

function BatchedHeterogeneousFeaturedGraph{T}(fgs::Vector{FG}) where {T <: Real, FG <: HeterogeneousFeaturedGraph}
    ngraphs = length(fgs)
    maxNumberOfConstraintNodes = Base.maximum(n_constraint_node, fgs)
    maxNumberOfVariableNodes = Base.maximum(n_variable_node, fgs)
    maxNumberOfValueNodes = Base.maximum(n_value_node, fgs)
    connfLength = size(fgs[1].connf, 1) # size of the feature vector for the constraint nodes.
    varnfLength = size(fgs[1].varnf, 1) # size of the feature vector for the variable nodes.
    valnfLength = size(fgs[1].valnf, 1) # size of the feature vector for the value nodes.
    gfLength = size(fgs[1].gf, 1) # size of the feature vector for the graph.

    contovar = zeros(T, maxNumberOfConstraintNodes, maxNumberOfVariableNodes, ngraphs)
    valtovar = zeros(T, maxNumberOfValueNodes, maxNumberOfVariableNodes, ngraphs)
    connf = zeros(T, connfLength, maxNumberOfConstraintNodes, ngraphs)
    varnf = zeros(T, varnfLength, maxNumberOfVariableNodes, ngraphs)
    valnf = zeros(T, valnfLength, maxNumberOfValueNodes, ngraphs)
    gf = zeros(T, gfLength, ngraphs)

    for (i, fg) in enumerate(fgs)
        contovar[1:n_constraint_node(fg),1:n_variable_node(fg),i] = fg.contovar
        valtovar[1:n_value_node(fg),1:n_variable_node(fg),i] = fg.valtovar
        connf[:, 1:n_constraint_node(fg), i] = fg.connf
        varnf[:, 1:n_variable_node(fg), i] = fg.varnf
        valnf[:, 1:n_value_node(fg), i] = fg.valnf
        gf[:, i] = fg.gf
    end

    return BatchedHeterogeneousFeaturedGraph{T}(contovar, valtovar, connf, varnf, valnf, gf)
end

BatchedHeterogeneousFeaturedGraph(fgs::Vector{FG}) where {FG <: FeaturedGraph} = BatchedHeterogeneousFeaturedGraph{Float32}(fgs)
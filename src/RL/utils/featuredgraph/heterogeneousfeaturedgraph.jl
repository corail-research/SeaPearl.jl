mutable struct HeterogeneousFeaturedGraph{T<:AbstractMatrix,N<:AbstractMatrix,G<:AbstractVector} <: AbstractFeaturedGraph
    contovar::T
    valtovar::T
    varnf::N
    connf::N
    valnf::N
    gf::G

    function HeterogeneousFeaturedGraph(contovar::T, valtovar::T, varnf::N, connf::N, valnf::N, gf::G) where {T<:AbstractMatrix,N<:AbstractMatrix,G<:AbstractVector}
        check_dimensions(contovar, valtovar, varnf, connf, valnf, gf)
        return new{T,N,G}(contovar, valtovar, varnf, connf, valnf, gf)
    end

    function HeterogeneousFeaturedGraph{T,N,G}(contovar::AbstractArray, valtovar::AbstractArray, varnf::AbstractArray, connf::AbstractArray, valnf::AbstractArray, gf::AbstractArray) where {T<:AbstractMatrix,N<:AbstractMatrix,G<:AbstractVector}
        check_dimensions(contovar, valtovar, varnf, connf, valnf, gf)
        return new{T,N,G}(contovar, valtovar, varnf, connf, valnf, gf)
    end
end

# ========== Accessing ==========

"""
    variable_node_feature(::HeterogeneousFeaturedGraph)
Return the variable nodes features matrix of the graph.
"""
variable_node_feature(fg::HeterogeneousFeaturedGraph) = fg.varnf

"""
    constraint_node_feature(::HeterogeneousFeaturedGraph)
Return the constraint nodes features matrix of the graph.
"""
constraint_node_feature(fg::HeterogeneousFeaturedGraph) = fg.connf

"""
    value_node_feature(::HeterogeneousFeaturedGraph)
Return the value nodes features matrix of the graph.
"""
value_node_feature(fg::HeterogeneousFeaturedGraph) = fg.valnf

"""
    n_variable_node(::HeterogeneousFeaturedGraph)
Return the number of variable nodes of the graph.
"""
n_variable_node(fg::HeterogeneousFeaturedGraph) = size(fg.varnf,2)

"""
    n_constraint_node(::HeterogeneousFeaturedGraph)
Return the number of constraint nodes of the graph.
"""
n_constraint_node(fg::HeterogeneousFeaturedGraph) = size(fg.connf,2)

"""
    n_value_node(::HeterogeneousFeaturedGraph)
Return the number of value nodes of the graph.
"""
n_value_node(fg::HeterogeneousFeaturedGraph) = size(fg.valnf,2)

"""
    global_feature(::HeterogeneousFeaturedGraph)
Return the global feature vector of the graph.
"""
global_feature(fg::HeterogeneousFeaturedGraph) = fg.gf
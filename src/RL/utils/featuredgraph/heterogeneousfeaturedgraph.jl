mutable struct HeterogeneousFeaturedGraph{T <: AbstractMatrix, N <: AbstractMatrix, E <: AbstractArray, G <: AbstractVector} <: AbstractFeaturedGraph
    contovar::T
    valtovar::T
    connf::N
    varnf::N
    valnf::N
    gf::G
    
    function HeterogeneousFeaturedGraph(contovar::T, valtovar::T, connf::N, varnf::N, valnf::N, gf::G) where {T <: AbstractMatrix, N <: AbstractMatrix, E <: AbstractArray, G <: AbstractVector}
        check_dimensions(contovar, valtovar, connf, varnf, valnf, gf)
        return new{T,N,E,G}(contovar, valtovar, connf, varnf, valnf, gf)
    end

    function HeterogeneousFeaturedGraph{T, N, E, G}(contovar::AbstractArray, valtovar::AbstractArray, connf::AbstractArray, varnf::AbstractArray, valnf::AbstractArray, gf::AbstractArray) where {T <: AbstractMatrix, N <: AbstractMatrix, E <: AbstractArray, G <: AbstractVector}
        check_dimensions(contovar, valtovar, connf, varnf, valnf, gf)
        return new{T, N, E, G}(contovar, valtovar, connf, varnf, valnf, gf)
    end
end

# ========== Accessing ==========

"""
    constraint_node_feature(::FeaturedGraph)
Return the constraint nodes features matrix of the graph.
"""
constraint_node_feature(fg::FeaturedGraph) = fg.connf

"""
    variable_node_feature(::FeaturedGraph)
Return the variable nodes features matrix of the graph.
"""
variable_node_feature(fg::FeaturedGraph) = fg.varnf

"""
    value_node_feature(::FeaturedGraph)
Return the value nodes features matrix of the graph.
"""
value_node_feature(fg::FeaturedGraph) = fg.valnf

"""
    n_constraint_node(::FeaturedGraph)
Return the number of constraint nodes of the graph.
"""
n_constraint_node(fg::FeaturedGraph) = fg.size()

"""
    n_variable_node(::FeaturedGraph)
Return the number of variable nodes of the graph.
"""
n_variable_node(fg::FeaturedGraph) = fg.size()

"""
    n_value_node(::FeaturedGraph)
Return the number of value nodes of the graph.
"""
n_value_node(fg::FeaturedGraph) = fg.size()

"""
    global_feature(::FeaturedGraph)
Return the global feature vector of the graph.
"""
global_feature(fg::FeaturedGraph) = fg.gf
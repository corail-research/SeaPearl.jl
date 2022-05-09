mutable struct HeterogeneousFeaturedGraph{T <: AbstractMatrix, N <: AbstractMatrix, E <: AbstractArray, G <: AbstractVector} <: AbstractFeaturedGraph
    conToVar::T
    valToVar::T
    connf::N
    varnf::N
    valnf::N
    ef::E
    gf::G
    directed::Bool
    
    function HeterogeneousFeaturedGraph(conToVar::T, valToVar::T, connf::N, varnf::N, valnf::N, ef::E, gf::G, directed::Bool) where {T <: AbstractMatrix, N <: AbstractMatrix, E <: AbstractArray, G <: AbstractVector}
        check_dimensions(conToVar, valToVar, connf, varnf, valnf, ef, gf)
        return new{T,N,E,G}(conToVar, valToVar, connf, varnf, valnf, ef, gf, directed)
    end

    function HeterogeneousFeaturedGraph{T, N, E, G}(conToVar::AbstractArray, valToVar::AbstractArray, connf::AbstractArray, varnf::AbstractArray, valnf::AbstractArray, ef::AbstractArray, gf::AbstractArray, directed) where {T <: AbstractMatrix, N <: AbstractMatrix, E <: AbstractArray, G <: AbstractVector}
        check_dimensions(conToVar, valToVar, connf, varnf, valnf, ef, gf)
        return new{T, N, E, G}(conToVar, valToVar, connf, varnf, valnf, ef, gf, directed)
    end
end
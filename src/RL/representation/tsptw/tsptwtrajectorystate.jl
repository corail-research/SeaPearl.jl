struct TsptwTrajectoryState <: GraphTrajectoryState
    fg::FeaturedGraph
    variableIdx::Int
    possibleValuesIdx::AbstractVector{Int}
end

Flux.@functor TsptwTrajectoryState

Base.length(::TsptwTrajectoryState) = 1

function Base.iterate(s::TsptwTrajectoryState, state::Union{Int,Nothing}=1)
    if isnothing(state)
        return nothing
    else
        return (s,nothing)
    end
end
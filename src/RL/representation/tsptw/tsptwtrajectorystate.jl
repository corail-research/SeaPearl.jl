struct TsptwTrajectoryState <: GraphTrajectoryState
    fg::FeaturedGraph
    variableIdx::Int
    possibleValuesIdx::AbstractVector{Int}
end

Flux.@functor TsptwTrajectoryState
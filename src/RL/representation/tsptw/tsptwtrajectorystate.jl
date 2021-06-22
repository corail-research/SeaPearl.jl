struct TsptwTrajectoryState <: GraphTrajectoryState
    fg::GeometricFlux.FeaturedGraph
    variableIdx::Int
    possibleValuesIdx::AbstractVector{Int}
end

Flux.@functor TsptwTrajectoryState
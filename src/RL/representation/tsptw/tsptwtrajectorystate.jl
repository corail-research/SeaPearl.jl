struct TsptwTrajectoryState <: GraphTrajectoryState
    fg::GraphSignals.FeaturedGraph
    variableIdx::Int
    possibleValuesIdx::AbstractVector{Int}
end

Flux.functor(::Type{TsptwTrajectoryState}, s) = (s.fg, s.possibleValuesIdx), ls -> TsptwTrajectoryState(ls[1], s.variableIdx, ls[2])

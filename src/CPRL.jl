module CPRL

using ReinforcementLearning
const RL = ReinforcementLearning

include("trailer.jl")
include("CP/CP.jl")
include("MOI_wrapper/MOI_wrapper.jl")
include("datagen/datagen.jl")
include("training.jl")

(app::RL.AbstractApproximator)(obs::NamedTuple{(:reward, :terminal, :state, :legal_actions, :legal_actions_mask)}) = app.model(obs)
(app::RL.AbstractApproximator)(state::CPGraph) = app.model(state)

greet() = print("Hello World!")

export

#Graph
edges, has_edge, nv, ne, CPLayerGraph

end # module

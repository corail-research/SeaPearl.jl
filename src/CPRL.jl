module CPRL

using ReinforcementLearning
const RL = ReinforcementLearning

include("trailer.jl")
include("CP/CP.jl")
include("MOI_wrapper/MOI_wrapper.jl")
include("datagen/datagen.jl")
include("training.jl")

(app::RL.NeuralNetworkApproximator)(obs::NamedTuple{(:reward, :terminal, :state, :legal_actions, :legal_actions_mask)}) = app.model(obs)
(app::RL.NeuralNetworkApproximator)(state::CPGraph) = app.model(state)

(app::RL.NeuralNetworkApproximator)(state::CPGraph, a::Int) = app.model(state)[a]



greet() = print("Hello World!")

export

#Graph
edges, has_edge, nv, ne, CPLayerGraph

end # module

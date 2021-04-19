module SeaPearl

using ReinforcementLearning
const RL = ReinforcementLearning

include("abstract_types.jl")

include("trailer.jl")
include("CP/CP.jl")
include("MOI_wrapper/MOI_wrapper.jl")
include("datagen/datagen.jl")
include("experiment/experiment.jl")

greet() = print("Hello World!")

export

#Graph
edges, has_edge, nv, ne, CPLayerGraph

end # module

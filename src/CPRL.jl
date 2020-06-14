module CPRL

using ReinforcementLearning
const RL = ReinforcementLearning

include("trailer.jl")
include("CP/CP.jl")
include("MOI_wrapper/MOI_wrapper.jl")
include("datagen/datagen.jl")


greet() = print("Hello World!")

export

#Graph
edges, has_edge, nv, ne, CPLayerGraph

end # module

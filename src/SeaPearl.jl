module SeaPearl

using Random
using ReinforcementLearning
using Graphs
const RL = ReinforcementLearning

include("abstract_types.jl")

include("trailer.jl")
include("CP/CP.jl")
#include("MOI_wrapper/MOI_wrapper.jl")
include("datagen/datagen.jl")
include("experiment/experiment.jl")

greet() = print("Hello World!")

end # module

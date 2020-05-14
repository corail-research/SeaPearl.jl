module CPRL



include("trailer.jl")
include("CP/CP.jl")
include("MOI_wrapper/MOI_wrapper.jl")
include("RL/RL.jl")


greet() = print("Hello World!")

end # module

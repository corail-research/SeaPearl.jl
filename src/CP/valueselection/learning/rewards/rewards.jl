function f(x::AbstractIntVar,alpha::Float64)
    return 1/(assignedValue(x)+1)^alpha
end

include("defaultreward.jl")
include("smartreward.jl")
include("tsptwreward.jl")
include("CPReward.jl")
include("CPReward2.jl")
include("experimentalreward.jl")

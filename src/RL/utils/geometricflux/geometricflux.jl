using NNlib: batched_mul


abstract type pool end

struct maxPooling <: pool end
struct meanPooling <: pool end
struct sumPooling <: pool end

Flux.@functor sumPooling
Flux.@functor meanPooling
Flux.@functor maxPooling

include("edgeftleayer.jl")
include("graphconv.jl")
include("heterogeneousgraphconv.jl")
include("heterogeneousgraphconvinit.jl")
include("heterogeneousgraphtransformer.jl")
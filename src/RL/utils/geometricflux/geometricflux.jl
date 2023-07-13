using NNlib: batched_mul


abstract type Pool end

struct maxPooling <: Pool end
struct meanPooling <: Pool end
struct sumPooling <: Pool end

Flux.@functor sumPooling
Flux.@functor meanPooling
Flux.@functor maxPooling

include("edgeftleayer.jl")
include("graphconv.jl")
include("heterogeneousgraphconv.jl")
include("heterogeneousgraphconvinit.jl")
include("heterogeneousgraphtransformer.jl")

"""
    AbstractTrajectoryState

The `TrajectoryState` is a component of the `AbstractStateRepresentation` specifying how to store
this representation in the `trajectory` of the RL agent for learning.

It might be necessary to implement your own when defining a new state representation or
when another data formatting is necessary for learning. To implement a subtype of
`AbstractTrajectoryState` one must provide:
- a struct subtype of `TabularTrajectoryState` or `NonTabularTrajectoryState` depending on you usage.
- a constructor with signature `YourTrajectoryState(sr::YourStateRepresentation)`.
- a function `Flux.functor(::Type{YourTrajectoryState}, ts)` (see Flux.functor for further information).
- an NN model taking a `YourTrajectoryState` instance as an input.
"""
abstract type AbstractTrajectoryState end
Flux.functor(t::Type{<:AbstractTrajectoryState}, ts) = throw(ErrorException("missing function Flux.functor($(t), ::Any)."))

"""
    TabularTrajectoryState

Abstract subtype of `AbstractTrajectoryState` for array based representations of state.

This type isn't currently used, but it will certainly be a lot clearer if one can easily
distinguish between array based representations, and more exotic ones (e.g. graphs, named tuples...).
"""
abstract type TabularTrajectoryState <: AbstractTrajectoryState end

"""
    NonTabularTrajectoryState

Abstract subtype of `AbstractTrajectoryState` for non array based representations of state.

This type is th only one currently used, but it will certainly be a lot clearer if one can easily
distinguish between array based representations, and more exotic ones (e.g. graphs, named tuples...).
"""
abstract type NonTabularTrajectoryState <: AbstractTrajectoryState end
abstract type GraphTrajectoryState <: NonTabularTrajectoryState end

function Base.ndims(sr::GraphTrajectoryState) 
    return NaN
end 
"""
    AbstractStateRepresentation{TS}

The AbstractStateRepresentation is the abstract type of the structures representing the internal state of the
CPModel and eventually the state of the search in a way that will be as expressive as possible.

It requires a specific `AbstractTrajectoryState` to make the bridge between the internal state representation
and one the RL agent can use to decide of the value to be assigned when branching.

A user can use the `DefaultStateRepresentation` with the `DefaultTrajectoryState` provided by the package but
he has the possibility to define his own.

To define a new one, the user must provide:
- a new structure, subtype of `AbstractStateRepresentation` with the appropriate subtype of `AbstractTrajectoryState` and all its dependencies.
- a constructor from a `CPModel`, with keyword argument `action_space`.
- a function `update_representation!(::AbstractStateRepresentation, ::CPModel, ::AbstractIntVar)` to update the state representation at each step.

Look at the DefaultStateRepresentation to get inspired.
"""
abstract type AbstractStateRepresentation{TS <: AbstractTrajectoryState} end
update_representation!(sr::AbstractStateRepresentation, m::CPModel, x::AbstractIntVar) = throw(ErrorException("missing function update_representation!(::$(typeof(sr)), ::$(typeof(m)), ::$(typeof(x)))."))

"""
    trajectoryState(sr::AbstractStateRepresentation{TS})
    
Return a TrajectoryState based on the present state represented by `sr`.

The type of the returned object is defined by the `TS` parametric type defined in `sr`.
"""
trajectoryState(sr::AbstractStateRepresentation{TS}) where {TS} = TS(sr)


"""
    AbstractFeaturization

Every subtype of `FeaturizedStateRepresentation{F}` requires an `AbstractFeaturization`.

This type gives the possibility to characterise these feature based representations, and thus gives
the ability to easily define new ones. To implement your own featurization, one must provide:
- a struct subtype of `AbstractFeaturization` (no field is used by the `DefaultStateRepresentation`).
- a function `featurize(::FeaturizedStateRepresentation{YourFeaturization, TS}) where TS` returning a feature Matrix with features stored columnwise.
- a function `feature_length(::Type{<:FeaturizedStateRepresentation{YourFeaturization, TS} where TS}` returning the size of a feature vector.
- _optionally_ a function `update_features!(::FeaturizedStateRepresentation{YourFeaturization, TS}, ::CPModel) where TS` to update your feature vectors based on statistics gathered by the CP Model.
"""
abstract type AbstractFeaturization end

"""
    FeaturizedStateRepresentation{F, TS}

Abstract subtype of `AbstractStateRepresentation` specializing the type of features used in the representation.

When a user wants to try a new featurization with the same organisation of the featurized elements, instead of
having to completely redefine a new type of AbstractStateRepresentation, he can keep the same and
just use a new `AbstractFeaturization`.
"""
abstract type FeaturizedStateRepresentation{F <: AbstractFeaturization, TS} <: AbstractStateRepresentation{TS} end

featurize(sr::FeaturizedStateRepresentation) = throw(ErrorException("missing function featurize(::$(typeof(sr)))."))
function global_featurize(sr::FeaturizedStateRepresentation) end
function update_features!(::FeaturizedStateRepresentation, ::CPModel) end
feature_length(sr::Type{<:FeaturizedStateRepresentation}) = throw(ErrorException("missing function feature_length(::$(sr))."))
global_feature_length(sr::Type{<:FeaturizedStateRepresentation}) = 0

struct DefaultFeaturization <: AbstractFeaturization end

include("default/cp_layer/cp_layer.jl")
include("default/defaulttrajectorystate.jl")
include("default/defaultstaterepresentation.jl")
include("default/heterogeneoustrajectorystate.jl")
include("default/heterogeneousstaterepresentation.jl")
include("tsptw/tsptwstaterepresentation.jl")
include("graphplotutils.jl")

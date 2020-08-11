
"""
    AbstractStateRepresentation

The AbstractStateRepresentation is the abstract type of the structures representing the 
state of the CPModel and eventually the state of the search in a way that will be as 
expressive as possible. It also need to be easily "understood" by the LearnedHeuristic as 
it is the input that the RL agent has to decide the value to be assigned when branching.

A user can use the DefaultStateRepresentation provided by the package but he has the possibility
to define his own one.

To define a new one, the user need to:
- define a new structure, subtype of AbstractStateRepresentation
- create a constructor from a CPModel 
- define an `update_representation!` function
- define a `to_arraybuffer` function
- define a `featuredgraph` function
- define a `branchingvariable_id` function

To be able to work with variable action space, you also need to:
- define the `possible_values` function.

Look at the DefaultStateRepresentation to get inspired.
"""
abstract type AbstractStateRepresentation end 

"""
    AbstractFeaturization

Some AbstractStateRepresentation require a Featurization (`FeaturizedStateRepresentation{F}`), this for instance often the case when 
representing the state with a graph. This type give the possibility to characterise those 
representation by the way they are featurize and thus give the ability to easily define new
featuriations.
"""
abstract type AbstractFeaturization end

"""
    FeaturizedStateRepresentation{F}

This subtype of AbstractStateRepresentation is useful to define representations that require a featurization, this for instance 
often the case when representing the state with a graph. When a user wants to try a new featurization with the same organisation of
the featurized elements, instead of having to completely redefine a new type of AbstractStateRepresentation, he can keep the same and 
just use a new AbstractFeaturization. 
"""
abstract type FeaturizedStateRepresentation{F} <: AbstractStateRepresentation end

function featurize(::FeaturizedStateRepresentation{F}) where F <: AbstractFeaturization
    throw(ErrorException("Featurization $(F) not implemented."))
    nothing
end

include("default/defaultstaterepresentation.jl")
include("tsptw/tsptwstaterepresentation.jl")
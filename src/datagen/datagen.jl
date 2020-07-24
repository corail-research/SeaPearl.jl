
"""
    AbstractModelGenerator

Abstract type of problem generators. They are used to fill a CPModel which will be solved to train 
a LearnedHeuristic. Some Generators are provided directly with the package but a user can also create
his own problem generator. 
"""
abstract type AbstractModelGenerator end

include("coloring.jl")
include("knapsack.jl")
"""
    AbstractVariableSelection{TakeObjective}

Abstract type for the variable selection. TakeObjective is a boolean saying if one can branch 
on the objective or not. 
"""
abstract type AbstractVariableSelection{TakeObjective} end

include("mindomain.jl")
include("random.jl")
include("failureBased.jl")
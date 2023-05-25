
"""
    LearningPhase
    
Might be changed to SolvingPhase or SearchingPhase.

They are four phases encountered during Learning (or rather Solving).
- The InitializingPhase: before starting the search, some elements have to be initialised
in accordance to the current model.
- The StepPhase: a step is the simple fact of going from a CP State to another eather by assigning a value, removing a value.
- The DecisionPhase: the moment when a value selection heuristic takes a decision of assigning a value to a variable.
- The EndingPhase: when all nodes have been visited or a limit has been reached, this is just after the end of the search.
"""
abstract type LearningPhase end

struct InitializingPhase <: LearningPhase end
struct StepPhase <: LearningPhase end 
struct DecisionPhase <: LearningPhase end 
struct EndingPhase <: LearningPhase end

include("../../RL/RL.jl")
include("searchmetrics.jl")

abstract type ValueSelection end

include("classic/random.jl")
include("classic/basicheuristic.jl")
include("classic/impactheuristic.jl")

abstract type ActionOutput end
struct VariableOutput <: ActionOutput end
struct FixedOutput <: ActionOutput end

include("learning/learning.jl")


abstract type LearningPhase end

struct InitializingPhase <: LearningPhase end
struct StepPhase <: LearningPhase end 
struct DecisionPhase <: LearningPhase end 
struct EndingPhase <: LearningPhase end

include("../../RL/RL.jl")

abstract type ValueSelection end

include("basicheuristic.jl")

abstract type ActionOutput end
struct VariableOutput <: ActionOutput end
struct FixedOutput <: ActionOutput end

include("learnedheuristic.jl")

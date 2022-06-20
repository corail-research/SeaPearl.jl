include("datasstructures/disjointSet.jl")

@enum filteringAlgorithmTypes begin
    algoTimeTabling
    algoDetectablePrecedence 
end

"""
    mutable struct Task(    earliestStartingTime::SeaPearl.IntVar, processingTime::Int, id::Int)

Task stucture with a earliestStartingTime variable, a processing time constant and an ID
"""
mutable struct Task
    earliestStartingTime::AbstractIntVar
    processingTime::Int
    id::Int
end

"""
    getEST(task::Task)

return the earliest starting time of a task.
"""
function getEST(task::Task)
    return task.earliestStartingTime.domain.min.value
end

"""
    getLCT(task::Task)

return the latest completion time of a task.
"""
function getLCT(task::Task)
    return task.earliestStartingTime.domain.max.value + task.processingTime
end

"""
    getECT(task::Task)

return the earliest completion time of a task.
"""
function getECT(task::Task)
    return task.earliestStartingTime.domain.min.value + task.processingTime
end

"""
    getLST(task::Task)

return the latest starting time of a task.
"""
function getLST(task::Task)
    return task.earliestStartingTime.domain.max.value
end

"""
    function Disjunctive(earliestStartingTime::Array{AbstractIntVar}, 
        processingTime::Array{Int}, trailer)::Disjunctive

Constraint that insure that no task are executed in the same time range, i.e. 
"""
struct Disjunctive <: Constraint
    
    tasks::Array{Task}
    active::StateObject{Bool}
    filteringAlgorithm::Array{filteringAlgorithmTypes}

    function Disjunctive(earliestStartingTime::Array{<:AbstractIntVar}, 
                        processingTime::Array{Int}, trailer, filteringAlgorithm::Array{filteringAlgorithmTypes} = [algoTimeTabling])::Disjunctive

        tasks = []
        for i in 1:size(earliestStartingTime)[1]
            push!(tasks, Task(earliestStartingTime[i], 
                             processingTime[i],
                             i))
        end 
        constraint = new(tasks, StateObject{Bool}(true, trailer), filteringAlgorithm)
        for i in 1:size(earliestStartingTime)[1]
            addOnDomainChange!(earliestStartingTime[i], constraint)
        end
        return constraint
    end
end



"""
    function propagate!(constraint::Disjunctive, toPropagate::Set{Constraint}, prunedDomains::CPModification)
        S_i + p_i <= S_j or S_j + p_j <= S_i
disjunctive propagate function. 
    There is two possibles filterings algorithme : timetabling and detectable precedences.
"""

function propagate!(constraint::Disjunctive, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if algoTimeTabling in constraint.filteringAlgorithm && algoDetectablePrecedence in constraint.filteringAlgorithm
        resultTimeTabling = timeTabling!(constraint, toPropagate, prunedDomains)
        resultDetectablePrecedence = detectablePrecedence!(constraint, toPropagate, prunedDomains)
        return resultDetectablePrecedence && resultTimeTabling
    elseif algoTimeTabling in constraint.filteringAlgorithm
        return timeTabling!(constraint, toPropagate, prunedDomains)
    else 
        return detectablePrecedence!(constraint, toPropagate, prunedDomains)
    end
end

"""
    function timeTabling!(constraint::Disjunctive, toPropagate::Set{Constraint}, prunedDomains::CPModification)
        The implementation is the timetabling as described in this paper : http://www2.ift.ulaval.ca/~quimper/publications/TimeLineProject.pdf
"""
function timeTabling!(constraint::Disjunctive, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    NumberOfTaskWithCompulsaryPart = 1
    lowerBoundCompulsaryPart = []
    upperBoundCompulsaryPart = []
    nextTaskWithClosestCompulsaryPart = fill(0, size(constraint.tasks)[1])
    filteredEST = [i.earliestStartingTime.domain.min.value for i in constraint.tasks]
    tasksOrderedByLST = sort(constraint.tasks, by = x-> x.earliestStartingTime.domain.max.value)
    tasksOrderedByEST = sort(constraint.tasks, by = x-> x.earliestStartingTime.domain.min.value)
    tasksOrderedByPT = sort(constraint.tasks, by = x-> x.processingTime)

    for task in tasksOrderedByLST
        #If the task as a compulsary part
        if getLST(task) < getECT(task)
            if (NumberOfTaskWithCompulsaryPart > 1)
                if (upperBoundCompulsaryPart[NumberOfTaskWithCompulsaryPart - 1] > getLST(task))
                    return false
                else
                    filteredEST[task.id] = max(filteredEST[task.id], upperBoundCompulsaryPart[NumberOfTaskWithCompulsaryPart - 1])
                end
            end
            push!(lowerBoundCompulsaryPart, getLST(task))
            push!(upperBoundCompulsaryPart, filteredEST[task.id] + task.processingTime)
            NumberOfTaskWithCompulsaryPart = NumberOfTaskWithCompulsaryPart + 1
        end
    end
    #if no task has a compulsary part, no need to filter.
    if NumberOfTaskWithCompulsaryPart == 1
        return true
    end

    iterator = 1
    for task in tasksOrderedByEST
        while (iterator < NumberOfTaskWithCompulsaryPart && getEST(task) >= upperBoundCompulsaryPart[iterator])
            iterator = iterator + 1
        end
        nextTaskWithClosestCompulsaryPart[task.id] = iterator
    end

    nextPart = SeaPearl.DisjointSet(NumberOfTaskWithCompulsaryPart)
    for task in tasksOrderedByPT
        if (getECT(task) <= getLST(task))
            nextTask = nextTaskWithClosestCompulsaryPart[task.id]
            firstUpdate = true
            while (nextTask < NumberOfTaskWithCompulsaryPart && filteredEST[task.id] + task.processingTime > lowerBoundCompulsaryPart[nextTask])
                nextTask = SeaPearl.greatest!(nextPart, nextTask)
                filteredEST[task.id] = max(filteredEST[task.id], upperBoundCompulsaryPart[nextTask])
                if (filteredEST[task.id] + task.processingTime > getLCT(task))
                    return false
                end
                if (!firstUpdate)
                    SeaPearl.setUnion!(nextPart,nextTaskWithClosestCompulsaryPart[task.id], nextTask)
                end
                firstUpdate = false
                nextTask = nextTask + 1
            end
        end
    end
    for i in 1:length(constraint.tasks)
        if  filteredEST[i] > constraint.tasks[i].earliestStartingTime.domain.max.value
            return false
        end
        if  filteredEST[i] > constraint.tasks[i].earliestStartingTime.domain.min.value
            prunedEST = SeaPearl.removeBelow!(constraint.tasks[i].earliestStartingTime.domain, filteredEST[i])
            addToPrunedDomains!(prunedDomains, constraint.tasks[i].earliestStartingTime, prunedEST)
            triggerDomainChange!(toPropagate, constraint.tasks[i].earliestStartingTime)
        end
    end

    if all(task -> length(task.earliestStartingTime.domain) <= 1, constraint.tasks)
        setValue!(constraint.active, false)
    end

    return true
end


"""
    function detectablePrecedence!(constraint::Disjunctive, toPropagate::Set{Constraint}, prunedDomains::CPModification)
        The implementation is the detectable precedences as described in this paper : http://www2.ift.ulaval.ca/~quimper/publications/TimeLineProject.pdf
"""
function detectablePrecedence!(constraint::Disjunctive, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    timeline = SeaPearl.Timeline(constraint.tasks)
    orderedTaskByLST = sort(constraint.tasks, by = x-> x.earliestStartingTime.domain.max.value)
    orderedTaskByECT = sort(constraint.tasks, by = x-> x.earliestStartingTime.domain.min.value + x.processingTime)
    postponedTasks = []
    blockingTask = nothing
    currentTaskIndex = 1
    currentTask = orderedTaskByLST[currentTaskIndex]
    filteredEST = fill(-1, size(constraint.tasks))
    for task in orderedTaskByECT
        while currentTaskIndex < length(constraint.tasks) && SeaPearl.getLST(currentTask) < SeaPearl.getECT(task)
            if SeaPearl.getLST(currentTask) >= SeaPearl.getECT(currentTask)
                SeaPearl.scheduleTask(timeline, currentTask)
            else
                if blockingTask !== nothing
                    return false
                end
                blockingTask = currentTask
            end
            currentTaskIndex += 1
            currentTask = orderedTaskByLST[currentTaskIndex]
        end
        if blockingTask === nothing
            filteredEST[task.id] = max(getEST(task), SeaPearl.earliestCompletionTime(timeline))
        else
            if blockingTask == task
                filteredEST[task.id] = max(getEST(task), SeaPearl.earliestCompletionTime(timeline))
                SeaPearl.scheduleTask(timeline, blockingTask)
                for postponedTask in postponedTasks
                    filteredEST[postponedTask.id] = max(SeaPearl.getEST(postponedTask), SeaPearl.earliestCompletionTime(timeline))
                end
                blockingTask = nothing 
                postponedTasks = []
            else
                push!(postponedTasks, task)
            end
        end
    end

    for i in 1:length(constraint.tasks)
        if  filteredEST[i] > constraint.tasks[i].earliestStartingTime.domain.max.value
            return false
        end
        if  filteredEST[i] > constraint.tasks[i].earliestStartingTime.domain.min.value
            prunedEST = SeaPearl.removeBelow!(constraint.tasks[i].earliestStartingTime.domain, filteredEST[i])
            addToPrunedDomains!(prunedDomains, constraint.tasks[i].earliestStartingTime, prunedEST)
            triggerDomainChange!(toPropagate, constraint.tasks[i].earliestStartingTime)
        end
    end

    if all(task -> length(task.earliestStartingTime.domain) <= 1, constraint.tasks)
        setValue!(constraint.active, false)
    end
    return true
end

variablesArray(constraint::Disjunctive) = [task.earliestStartingTime for task in constraint.tasks]

function variablesArray(constraint::Disjunctive) 
    variables = [task.earliestStartingTime for task in constraint.tasks]
    varviews = []
    for var in variables
        for varview in var.children
            if isa(varview, IntVarViewOffset)
                push!(variables,varview)
            end
        end
    end
    append!(variables,varviews)
    return variables
end

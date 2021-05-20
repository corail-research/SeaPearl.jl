include("datasstructures/disjointSet.jl")
mutable struct Task
    earliestStartingTime::SeaPearl.IntVar
    processingTime::Int
    id::Int
end

function getEST(task::Task)
    return task.earliestStartingTime.domain.min.value
end

function getLCT(task::Task)
    return task.earliestStartingTime.domain.max.value + task.processingTime
end
function getECT(task::Task)
    return task.earliestStartingTime.domain.min.value + task.processingTime
end

function getLST(task::Task)
    return task.earliestStartingTime.domain.max.value
end


struct Disjunctive <: Constraint
    tasks::Array{Task}
    active::StateObject{Bool}

    function Disjunctive(earliestStartingTime::Array{IntVar}, 
                        processingTime::Array{Int}, trailer)::Disjunctive
        tasks = []
        for i in 1:size(earliestStartingTime)[1]
            push!(tasks, Task(earliestStartingTime[i], 
                             processingTime[i],
                             i))
        end 
        constraint = new(tasks, StateObject{Bool}(true, trailer))
        for i in 1:size(earliestStartingTime)[1]
            addOnDomainChange!(earliestStartingTime[i], constraint)
        end
        return constraint
    end
end

function propagate!(constraint::Disjunctive, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    taskNumberWithCompulsaryPart = 1
    lowerBoundCompulsaryPart = []
    upperBoundCompulsaryPart = []
    nextTaskWithClosestCompulsaryPart = fill(0, size(constraint.tasks)[1])
    filteredEST = [i.earliestStartingTime.domain.min.value for i in constraint.tasks]
    tasksOrderedByLST = sort(constraint.tasks, by = x-> x.earliestStartingTime.domain.max.value)
    tasksOrderedByEST = sort(constraint.tasks, by = x-> x.earliestStartingTime.domain.min.value)
    tasksOrderedByPT = sort(constraint.tasks, by = x-> x.processingTime)

    for task in tasksOrderedByLST
        if getLST(task) < getECT(task)
            if (taskNumberWithCompulsaryPart > 1)
                if (upperBoundCompulsaryPart[taskNumberWithCompulsaryPart - 1] > getLST(task))
                    return false
                else
                    filteredEST[task.id] = max(filteredEST[task.id], upperBoundCompulsaryPart[taskNumberWithCompulsaryPart - 1])
                end
            end
            push!(lowerBoundCompulsaryPart, getLST(task))
            push!(upperBoundCompulsaryPart, filteredEST[task.id] + task.processingTime)
            taskNumberWithCompulsaryPart = taskNumberWithCompulsaryPart + 1
        end
    end

    if taskNumberWithCompulsaryPart == 1
        return true
    end

    iterator = 1
    for task in tasksOrderedByEST
        while (iterator < taskNumberWithCompulsaryPart && getEST(task) >= upperBoundCompulsaryPart[iterator])
            iterator = iterator + 1
        end
        nextTaskWithClosestCompulsaryPart[task.id] = iterator
    end
    nextPart = SeaPearl.DisjointSet(taskNumberWithCompulsaryPart)
    for task in tasksOrderedByPT
        if (getECT(task) <= getLST(task))
            c = nextTaskWithClosestCompulsaryPart[task.id]
            firstUpdate = true
            while (c < taskNumberWithCompulsaryPart && filteredEST[task.id] + task.processingTime > lowerBoundCompulsaryPart[c])
                c = SeaPearl.greatest!(nextPart,c)
                filteredEST[task.id] = max(filteredEST[task.id], upperBoundCompulsaryPart[c])
                if (filteredEST[task.id] + task.processingTime > getLCT(task))
                    return false
                end
                if (!firstUpdate)
                    SeaPearl.setUnion!(nextPart,nextTaskWithClosestCompulsaryPart[task.id], c)
                end
                firstUpdate = false
                c = c + 1
            end
        end
    end
    for i in 1:size(constraint.tasks)[1]
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
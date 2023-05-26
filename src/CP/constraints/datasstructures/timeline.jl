include("disjointset.jl")

"""
    Timeline(tasks::Array{Task}) 

Timeline data structure presented in 
"""
mutable struct Timeline
    timePoints::Array{Int}
    timePointsCapacity::Array{Int}
    mapTaskIndexTimePoint::Array{Int}
    lastestDecrementedTimePoint::Int
    disjointSet::DisjointSet
    function Timeline(tasks::Array{Task}) 
        tasksSortedByEst = sort(tasks, by = x-> minimum(x.earliestStartingTime.domain))
        timePoints = []
        timePointsCapacity = []
        mapTaskIndexTimePoint = fill(-1, length(tasks))
        maxLCT = 0 
        sumProcessingTime = 0
        for task in tasksSortedByEst
            if length(timePoints) == 0 || timePoints[length(timePoints)] != SeaPearl.getEST(task)
                push!(timePoints, SeaPearl.getEST(task))
            end
            mapTaskIndexTimePoint[task.id] = length(timePoints)
            sumProcessingTime += task.processingTime
            if (SeaPearl.getLCT(task) > maxLCT)
                maxLCT = SeaPearl.getLCT(task)
            end
        end
        push!(timePoints, maxLCT + sumProcessingTime)
        for timePoint in 1:length(timePoints)-1
            push!(timePointsCapacity, timePoints[timePoint + 1] - timePoints[timePoint])
        end
        disjointSet = SeaPearl.DisjointSet(length(timePoints))
        lastestDecrementedTimePoint = -1
        return new(timePoints, timePointsCapacity, mapTaskIndexTimePoint, lastestDecrementedTimePoint, disjointSet)
    end
end

"""
    scheduleTask(timeline::Timeline, task::Task)

    Scheduled the task on the timeline at the earliest moment 
"""
function scheduleTask(timeline::Timeline, task::Task)
    timeToSchedule = task.processingTime
    timePoint = SeaPearl.greatest!(timeline.disjointSet, timeline.mapTaskIndexTimePoint[task.id])
    while timeToSchedule > 0
        timeToScheduleAtThatTimePoint = min(timeline.timePointsCapacity[timePoint], timeToSchedule)
        timeToSchedule -= timeToScheduleAtThatTimePoint
        timeline.timePointsCapacity[timePoint] -= timeToScheduleAtThatTimePoint
        if timeline.timePointsCapacity[timePoint] == 0
            representative1 = SeaPearl.findRepresentative!(timeline.disjointSet, timePoint)
            representative2 = SeaPearl.findRepresentative!(timeline.disjointSet, timePoint + 1)
            SeaPearl.setUnion!(timeline.disjointSet, representative1, representative2)
            timePoint = SeaPearl.greatest!(timeline.disjointSet, timePoint)
        end
    end
    timeline.lastestDecrementedTimePoint = max(timeline.lastestDecrementedTimePoint, timePoint)
    return timeline.timePoints[timePoint + 1] - timeline.timePointsCapacity[timePoint]
end

"""
    earliestCompletionTime(timeline::Timeline)

    Return the earliest completion time of the timeline with the tasks scheduled.
"""
function earliestCompletionTime(timeline::Timeline)
    if timeline.lastestDecrementedTimePoint >= 0
        return timeline.timePoints[timeline.lastestDecrementedTimePoint + 1] - timeline.timePointsCapacity[timeline.lastestDecrementedTimePoint]
    end
    return -1
end
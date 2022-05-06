@testset "timeline.jl" begin
    @testset "Timeline(tasks::Task)" begin
        trailer = SeaPearl.Trailer()
        startingTime1 = SeaPearl.IntVar(1, 3,"t1", trailer)
        startingTime2 = SeaPearl.IntVar(2, 4,"t1", trailer)
        startingTime3 = SeaPearl.IntVar(2, 5,"t1", trailer)
        task1 = SeaPearl.Task(startingTime1, 1, 1)
        task2 = SeaPearl.Task(startingTime2, 2, 2)
        task3 = SeaPearl.Task(startingTime3, 1, 3)
        tasks = [task1, task2, task3]
        timeline = SeaPearl.Timeline(tasks)

        @test length(timeline.timePoints) == 3
        @test timeline.timePoints[1] == 1
        @test timeline.timePoints[2] == 2
        @test timeline.timePoints[3] == 10

        @test length(timeline.timePointsCapacity) == 2
        @test timeline.timePointsCapacity[1] == 1
        @test timeline.timePointsCapacity[2] == 8

        @test length(timeline.mapTaskIndexTimePoint) == 3
        @test timeline.mapTaskIndexTimePoint[1] == 1
        @test timeline.mapTaskIndexTimePoint[2] == 2
        @test timeline.mapTaskIndexTimePoint[3] == 2
    end

    @testset "scheduleTask(timeline::Timeline, task::Task)" begin
        trailer = SeaPearl.Trailer()
        startingTime1 = SeaPearl.IntVar(1, 3,"t1", trailer)
        startingTime2 = SeaPearl.IntVar(2, 4,"t1", trailer)
        startingTime3 = SeaPearl.IntVar(2, 5,"t1", trailer)
        task1 = SeaPearl.Task(startingTime1, 1, 1)
        task2 = SeaPearl.Task(startingTime2, 2, 2)
        task3 = SeaPearl.Task(startingTime3, 1, 3)
        tasks = [task1, task2, task3]
        timeline = SeaPearl.Timeline(tasks)

        SeaPearl.scheduleTask(timeline, task1)
        @test timeline.timePointsCapacity[1] == 0
        @test timeline.timePointsCapacity[2] == 8
        @test SeaPearl.findRepresentative!(timeline.disjointSet, 1) == SeaPearl.findRepresentative!(timeline.disjointSet, 2)
        @test timeline.lastestDecrementedTimePoint == 2

        SeaPearl.scheduleTask(timeline, task2)
        @test timeline.timePointsCapacity[1] == 0
        @test timeline.timePointsCapacity[2] == 6
        @test SeaPearl.findRepresentative!(timeline.disjointSet, 1) == SeaPearl.findRepresentative!(timeline.disjointSet, 2)
        @test timeline.lastestDecrementedTimePoint == 2

        SeaPearl.scheduleTask(timeline, task3)
        @test timeline.timePointsCapacity[1] == 0
        @test timeline.timePointsCapacity[2] == 5
        @test SeaPearl.findRepresentative!(timeline.disjointSet, 1) == SeaPearl.findRepresentative!(timeline.disjointSet, 2)
        @test timeline.lastestDecrementedTimePoint == 2
    end

    @testset "earliestCompletionTime(timeline::Timeline)" begin
        trailer = SeaPearl.Trailer()
        startingTime1 = SeaPearl.IntVar(1, 3,"t1", trailer)
        startingTime2 = SeaPearl.IntVar(2, 4,"t1", trailer)
        startingTime3 = SeaPearl.IntVar(2, 5,"t1", trailer)
        task1 = SeaPearl.Task(startingTime1, 1, 1)
        task2 = SeaPearl.Task(startingTime2, 2, 2)
        task3 = SeaPearl.Task(startingTime3, 1, 3)
        tasks = [task1, task2, task3]
        timeline = SeaPearl.Timeline(tasks)

        SeaPearl.scheduleTask(timeline, task1)
        @test SeaPearl.earliestCompletionTime(timeline) == 2

        SeaPearl.scheduleTask(timeline, task2)
        @test SeaPearl.earliestCompletionTime(timeline) == 4

        SeaPearl.scheduleTask(timeline, task3)
        @test SeaPearl.earliestCompletionTime(timeline) == 5
    end

    @testset "Timeline(tasks::Task) example from paper" begin
        trailer = SeaPearl.Trailer()
        startingTime1 = SeaPearl.IntVar(4, 10,"t1", trailer)
        startingTime2 = SeaPearl.IntVar(1, 4,"t1", trailer)
        startingTime3 = SeaPearl.IntVar(5, 6,"t1", trailer)
        task1 = SeaPearl.Task(startingTime1, 5, 1)
        task2 = SeaPearl.Task(startingTime2, 6, 2)
        task3 = SeaPearl.Task(startingTime3, 2, 3)
        tasks = [task1, task2, task3]
        timeline = SeaPearl.Timeline(tasks)

        @test length(timeline.timePoints) == 4
        @test timeline.timePoints[1] == 1
        @test timeline.timePoints[2] == 4
        @test timeline.timePoints[3] == 5
        @test timeline.timePoints[4] == 28

        @test length(timeline.timePointsCapacity) == 3
        @test timeline.timePointsCapacity[1] == 3
        @test timeline.timePointsCapacity[2] == 1
        @test timeline.timePointsCapacity[3] == 23

        @test length(timeline.mapTaskIndexTimePoint) == 3
        @test timeline.mapTaskIndexTimePoint[1] == 2
        @test timeline.mapTaskIndexTimePoint[2] == 1
        @test timeline.mapTaskIndexTimePoint[3] == 3

        SeaPearl.scheduleTask(timeline, task1)
        @test timeline.timePointsCapacity[1] == 3
        @test timeline.timePointsCapacity[2] == 0
        @test timeline.timePointsCapacity[3] == 19
        @test SeaPearl.findRepresentative!(timeline.disjointSet, 2) == SeaPearl.findRepresentative!(timeline.disjointSet, 3)
        @test timeline.lastestDecrementedTimePoint == 3
        @test SeaPearl.earliestCompletionTime(timeline) == 9

        SeaPearl.scheduleTask(timeline, task2)
        @test timeline.timePointsCapacity[1] == 0
        @test timeline.timePointsCapacity[2] == 0
        @test timeline.timePointsCapacity[3] == 16
        @test SeaPearl.findRepresentative!(timeline.disjointSet, 1) == SeaPearl.findRepresentative!(timeline.disjointSet, 3)
        @test SeaPearl.findRepresentative!(timeline.disjointSet, 2) == SeaPearl.findRepresentative!(timeline.disjointSet, 3)
        @test timeline.lastestDecrementedTimePoint == 3
        @test SeaPearl.earliestCompletionTime(timeline) == 12

        SeaPearl.scheduleTask(timeline, task3)
        @test timeline.timePointsCapacity[1] == 0
        @test timeline.timePointsCapacity[2] == 0
        @test timeline.timePointsCapacity[3] == 14
        @test SeaPearl.findRepresentative!(timeline.disjointSet, 1) == SeaPearl.findRepresentative!(timeline.disjointSet, 3)
        @test SeaPearl.findRepresentative!(timeline.disjointSet, 2) == SeaPearl.findRepresentative!(timeline.disjointSet, 3)
        @test timeline.lastestDecrementedTimePoint == 3
        @test SeaPearl.earliestCompletionTime(timeline) == 14
    end
end
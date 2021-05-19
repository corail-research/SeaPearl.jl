@testset "disjunctive.jl" begin
    @testset "getEST(task::Task)" begin
        trailer = SeaPearl.Trailer()
        task1 = SeaPearl.IntVar(1, 3, "t1", trailer)
        task2 = SeaPearl.IntVar(2, 3, "t2", trailer)
        p1 = 2
        p2 = 3
        tasks = Vector{SeaPearl.IntVar}([task1, task2])
        processing_time = [p1,p2]
        constraint = SeaPearl.Disjunctive(tasks, processing_time, trailer)

        @test constraint.active.value
        @test SeaPearl.getEST(constraint.tasks[1]) == 1
        @test SeaPearl.getEST(constraint.tasks[2]) == 2
    end

    @testset "getLCT(task::Task)" begin
        trailer = SeaPearl.Trailer()
        task1 = SeaPearl.IntVar(1, 3, "t1", trailer)
        task2 = SeaPearl.IntVar(2, 3, "t2", trailer)
        p1 = 2
        p2 = 3
        tasks = Vector{SeaPearl.IntVar}([task1, task2])
        processing_time = [p1,p2]
        constraint = SeaPearl.Disjunctive(tasks, processing_time, trailer)

        @test constraint.active.value
        @test SeaPearl.getLCT(constraint.tasks[1]) == 5
        @test SeaPearl.getLCT(constraint.tasks[2]) == 6
    end

    @testset "getECT(task::Task)" begin
        trailer = SeaPearl.Trailer()
        task1 = SeaPearl.IntVar(1, 3, "t1", trailer)
        task2 = SeaPearl.IntVar(2, 3, "t2", trailer)
        p1 = 2
        p2 = 3
        tasks = Vector{SeaPearl.IntVar}([task1, task2])
        processing_time = [p1,p2]
        constraint = SeaPearl.Disjunctive(tasks, processing_time, trailer)

        @test constraint.active.value
        @test SeaPearl.getECT(constraint.tasks[1]) == 3
        @test SeaPearl.getECT(constraint.tasks[2]) == 5
    end

    @testset "getLST(task::Task)" begin
        trailer = SeaPearl.Trailer()
        task1 = SeaPearl.IntVar(1, 3, "t1", trailer)
        task2 = SeaPearl.IntVar(2, 3, "t2", trailer)
        p1 = 2
        p2 = 3
        tasks = Vector{SeaPearl.IntVar}([task1, task2])
        processing_time = [p1,p2]
        constraint = SeaPearl.Disjunctive(tasks, processing_time, trailer)

        @test constraint.active.value
        @test SeaPearl.getLST(constraint.tasks[1]) == 3
        @test SeaPearl.getLST(constraint.tasks[2]) == 3
    end

    @testset "propagate example from article" begin
        trailer = SeaPearl.Trailer()
        task1 = SeaPearl.IntVar(0, 1, "task1", trailer)
        task2 = SeaPearl.IntVar(1, 5, "task2", trailer)
        p1 = 4
        p2 = 1
        tasks = Vector{SeaPearl.IntVar}([task1, task2])
        processing_time = [p1,p2]
        constraint = SeaPearl.Disjunctive(tasks, processing_time, trailer)

        toPropagate = Set{SeaPearl.Constraint}([constraint])
        prunedDomains = SeaPearl.CPModification()

        res = SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test res
        @test length(task1.domain) == 2
        @test length(task2.domain) == 2
        @test 0 in task1.domain
        @test 1 in task1.domain
        @test 4 in task2.domain
        @test 5 in task2.domain
    end
    

    @testset "propagate! with 3 tasks" begin
        trailer = SeaPearl.Trailer()
        task1 = SeaPearl.IntVar(1, 3, "task1", trailer)
        task2 = SeaPearl.IntVar(2, 3, "task2", trailer)
        task3 = SeaPearl.IntVar(1, 5, "task3", trailer)

        p1 = 2
        p2 = 3
        p3 = 3
        tasks = Vector{SeaPearl.IntVar}([task1, task2, task3])
        processing_time = [p1, p2, p3]
        constraint = SeaPearl.Disjunctive(tasks, processing_time, trailer)

        toPropagate = Set{SeaPearl.Constraint}([constraint])
        prunedDomains = SeaPearl.CPModification()

        res = SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test res
        @test length(task1.domain) == 3
        @test length(task2.domain) == 2
        @test length(task3.domain) == 1
        @test 1 in task1.domain
        @test 2 in task1.domain
        @test 3 in task1.domain
        @test 2 in task2.domain
        @test 3 in task2.domain
        @test 5 in task3.domain
    end


    @testset "propagate! with 4 tasks" begin
        trailer = SeaPearl.Trailer()
        task1 = SeaPearl.IntVar(1, 1, "task1", trailer)
        task2 = SeaPearl.IntVar(8, 8, "task2", trailer)
        task3 = SeaPearl.IntVar(2, 3, "task3", trailer)
        task4 = SeaPearl.IntVar(1, 9, "task4", trailer)

        p1 = 2
        p2 = 1
        p3 = 3
        p4 = 3

        tasks = Vector{SeaPearl.IntVar}([task1, task2, task3, task4])
        processing_time = [p1, p2, p3, p4]
        constraint = SeaPearl.Disjunctive(tasks, processing_time, trailer)

        toPropagate = Set{SeaPearl.Constraint}([constraint])
        prunedDomains = SeaPearl.CPModification()

        res = SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test res
        @test length(task1.domain) == 1
        @test length(task2.domain) == 1
        @test length(task3.domain) == 1
        @test length(task4.domain) == 1

        @test 1 in task1.domain
        @test 8 in task2.domain
        @test 3 in task3.domain
        @test 9 in task4.domain

    end
end

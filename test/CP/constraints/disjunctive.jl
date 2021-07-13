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

    @testset "function Disjunctive(earliestStartingTime::Array{IntVar}, 
                    processingTime::Array{Int}, trailer)" begin

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

        @test size(constraint.tasks)[1] == 4
        @test constraint.active.value 
        @test constraint in task1.onDomainChange
        @test constraint in task2.onDomainChange
        @test constraint in task3.onDomainChange
        @test constraint in task4.onDomainChange

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
        @test !constraint.active.value
    end

    @testset "propagate! failed" begin
        trailer = SeaPearl.Trailer()
        task1 = SeaPearl.IntVar(1, 3, "task1", trailer)
        task2 = SeaPearl.IntVar(2, 3, "task2", trailer)
        task3 = SeaPearl.IntVar(1, 4, "task3", trailer)
        p1 = 2
        p2 = 3
        p3 = 3
        tasks = Vector{SeaPearl.IntVar}([task1, task2, task3])
        processing_time = [p1, p2, p3]
        constraint = SeaPearl.Disjunctive(tasks, processing_time, trailer)
    
        toPropagate = Set{SeaPearl.Constraint}([constraint])
        prunedDomains = SeaPearl.CPModification()
    
        res = SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
    
        @test !res
    end

    @testset "propagate! failed" begin
        trailer = SeaPearl.Trailer()

        task1 = SeaPearl.IntVar(1, 1, "task1", trailer)
        task2 = SeaPearl.IntVar(3, 3, "task2", trailer)
        task3 = SeaPearl.IntVar(5, 5, "task3", trailer)

        p1 = 2
        p2 = 3
        p3 = 3
        tasks = Vector{SeaPearl.IntVar}([task1, task2, task3])
        processing_time = [p1, p2, p3]

        constraint = SeaPearl.Disjunctive(tasks, processing_time, trailer)
    
        toPropagate = Set{SeaPearl.Constraint}([constraint])
        prunedDomains = SeaPearl.CPModification()
    
        res = SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        @test !res
    end

    @testset "propagate! full solving with fixed 3 tasks and Infeasible status" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        task1 = SeaPearl.IntVar(1, 1, "task1", trailer)
        task2 = SeaPearl.IntVar(3, 3, "task2", trailer)
        task3 = SeaPearl.IntVar(5, 5, "task3", trailer)

        p1 = 2
        p2 = 3
        p3 = 3
        SeaPearl.addVariable!(model, task1)
        SeaPearl.addVariable!(model, task2)
        SeaPearl.addVariable!(model, task3)

        tasks = Vector{SeaPearl.IntVar}([task1, task2, task3])
        processing_time = [p1, p2, p3]
        SeaPearl.addConstraint!(model,SeaPearl.Disjunctive(tasks, processing_time, trailer))

        variableSelection = SeaPearl.MinDomainVariableSelection{false}()
        status = SeaPearl.solve!(model; variableHeuristic=variableSelection)

        @test status == :Infeasible
        @test length(model.statistics.solutions) == 1 # one infeasible solution
    end

    @testset "propagate! full solving with 3 tasks and Infeasible status" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        task1 = SeaPearl.IntVar(1, 1, "task1", trailer)
        task2 = SeaPearl.IntVar(2, 3, "task2", trailer)
        task3 = SeaPearl.IntVar(1, 5, "task3", trailer)

        p1 = 2
        p2 = 3
        p3 = 3
        tasks = Vector{SeaPearl.IntVar}([task1, task2, task3])
        processing_time = [p1, p2, p3]
        SeaPearl.addConstraint!(model,SeaPearl.Disjunctive(tasks, processing_time, trailer))
        SeaPearl.addVariable!(model, task1)
        SeaPearl.addVariable!(model, task2)
        SeaPearl.addVariable!(model, task3)

        variableSelection = SeaPearl.MinDomainVariableSelection{false}()
        status = @time SeaPearl.solve!(model; variableHeuristic=variableSelection)

        @test status == :Infeasible
        @test model.statistics.numberOfSolutions == 0

    end

    @testset "propagate! chain" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        task1 = SeaPearl.IntVar(1, 3, "task1", trailer)
        task2 = SeaPearl.IntVar(2, 3, "task2", trailer)
        task3 = SeaPearl.IntVar(1, 7, "task3", trailer)

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
        @test length(task3.domain) == 3
        @test 1 in task1.domain
        @test 2 in task1.domain
        @test 3 in task1.domain
        @test 2 in task2.domain
        @test 3 in task2.domain
        @test 5 in task3.domain
        @test 6 in task3.domain
        @test 7 in task3.domain

        SeaPearl.remove!(task1.domain, 3)
        res = SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test res
        @test length(task1.domain) == 2
        @test length(task2.domain) == 1
        @test length(task3.domain) == 2
        @test 1 in task1.domain
        @test 2 in task1.domain
        @test 3 in task2.domain
        @test 6 in task3.domain
        @test 7 in task3.domain

        SeaPearl.remove!(task1.domain, 2)
        res = SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        @test res
        @test length(task1.domain) == 1
        @test length(task2.domain) == 1
        @test length(task3.domain) == 2
        @test 1 in task1.domain
        @test 3 in task2.domain
        @test 6 in task3.domain
        @test 7 in task3.domain
    end

    @testset "full solving with 3 tasks and optimal status" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        task1 = SeaPearl.IntVar(1, 1, "task1", trailer)
        task2 = SeaPearl.IntVar(2, 3, "task2", trailer)
        task3 = SeaPearl.IntVar(1, 6, "task3", trailer)
        SeaPearl.addVariable!(model, task1)
        SeaPearl.addVariable!(model, task2)
        SeaPearl.addVariable!(model, task3)

        p1 = 2
        p2 = 3
        p3 = 3
        tasks = Vector{SeaPearl.IntVar}([task1, task2, task3])
        processing_time = [p1, p2, p3]
        SeaPearl.addConstraint!(model,SeaPearl.Disjunctive(tasks, processing_time, trailer))

        variableSelection = SeaPearl.MinDomainVariableSelection{false}()
        status = @time SeaPearl.solve!(model; variableHeuristic=variableSelection)

        @test status == :Optimal
        @test model.statistics.numberOfSolutions == 1
        @test 1 in task1.domain
        @test 3 in task2.domain
        @test 6 in task3.domain
        @test 1 == length(task1.domain)
        @test 1 == length(task2.domain)
        @test 1 == length(task3.domain)
    end


    @testset "full solving with 3 tasks, optimal status and multiple solution" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        task1 = SeaPearl.IntVar(1, 1, "task1", trailer)
        task2 = SeaPearl.IntVar(2, 3, "task2", trailer)
        task3 = SeaPearl.IntVar(1, 7, "task3", trailer)
        SeaPearl.addVariable!(model, task1)
        SeaPearl.addVariable!(model, task2)
        SeaPearl.addVariable!(model, task3)

        p1 = 2
        p2 = 3
        p3 = 3
        tasks = Vector{SeaPearl.IntVar}([task1, task2, task3])
        processing_time = [p1, p2, p3]
        SeaPearl.addConstraint!(model,SeaPearl.Disjunctive(tasks, processing_time, trailer))

        variableSelection = SeaPearl.MinDomainVariableSelection{false}()
        status = @time SeaPearl.solve!(model; variableHeuristic=variableSelection)

        @test status == :Optimal
        @test model.statistics.numberOfSolutions == 2
        @test 1 in task1.domain
        @test 3 in task2.domain
        @test 6 in task3.domain
        @test 7 in task3.domain
        @test 1 == length(task1.domain)
        @test 1 == length(task2.domain)
        @test 2 == length(task3.domain)
    end



    @testset "job shop test wiht two tasks" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        nbMachine = 2
        nbTask = 2
        timeLimit = 10
        tasks = Matrix(undef, nbTask, nbMachine)
        objectif = SeaPearl.IntVar(0, timeLimit, "obj", trailer)
        SeaPearl.addVariable!(model, objectif)
        processingTime = [1 4; 4 1]
        endTask = Matrix(undef, nbTask, nbMachine)

        for i in 1:nbTask
            for j in 1:nbMachine
                tasks[i,j] = SeaPearl.IntVar(0, timeLimit, "task_"*string(i)*"_"*string(j), trailer)
                endTask[i,j] = SeaPearl.IntVarViewOffset(tasks[i,j], processingTime[i,j], "end_"*string(i)*"_"*string(j))
                SeaPearl.addVariable!(model, tasks[i,j])
                SeaPearl.addConstraint!(model, SeaPearl.LessOrEqual(endTask[i,j], objectif, trailer))
            end
        end

        for i in 1:nbTask
            SeaPearl.addConstraint!(model, SeaPearl.Disjunctive([tasks[i,j] for j in 1:nbMachine], 
                                                            [processingTime[i,j] for j in 1:nbMachine],
                                                            trailer))
        end
        for j in 1:nbMachine
            SeaPearl.addConstraint!(model, SeaPearl.Disjunctive([tasks[i,j] for i in 1:nbTask], 
                                                            [processingTime[i,j] for i in 1:nbTask],
                                                            trailer))
        end

        SeaPearl.addObjective!(model, objectif)
        variableSelection = SeaPearl.MinDomainVariableSelection{false}()
        status = @time SeaPearl.solve!(model; variableHeuristic=variableSelection,)

        @test status == :Optimal
        @test (model.statistics.solutions[end-1]["obj"]) == 5
    end
end
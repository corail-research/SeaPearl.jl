struct JobShopGenerator  <: AbstractModelGenerator
    numberOfMachines   :: Int
    numberOfJobs       :: Int
    maxTime            :: Int
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::GraphColoringGenerator)  
Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose.
"""
function fill_with_generator!(cpmodel::CPModel, gen::JobShopGenerator;  rng::AbstractRNG = MersenneTwister())
    job_times  =  fill(1, gen.numberOfJobs, gen.numberOfMachines) #each task needs to be run at least for 1 unit of time on each machine
    for i in 1:gen.numberOfJobs
        # One of these 2 lines should be uncommented. Uncomment the first one if there are more machines than jobs, the second one otherwise
        totalTimePerTask = Int(floor(gen.maxTime*0.5))
        #totalTimePerTask = Int(floor(gen.maxTime*(gen.numberOfMachines/gen.numberOfJobs)*0.5))
        for j in 1:totalTimePerTask-gen.numberOfMachines
            job_times[i,rand(rng, 1:j) % gen.numberOfMachines + 1] += 1
        end
    end

    job_order = mapreduce(permutedims, vcat, [randperm(rng, gen.numberOfMachines) for i in 1:gen.numberOfJobs])    #job_order for each task generated using random row-wise permutation.
    cpmodel.adhocInfo = Dict("numberOfMachines" => gen.numberOfMachines, "numberOfJobs" => gen.numberOfJobs, "job_times" => job_times, "job_order" => job_order)

    ### Variable declaration ###    

    # Start/End times for each machine and jobs
    job_start = Matrix{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs, gen.numberOfMachines)
    job_end = Matrix{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs, gen.numberOfMachines)

    # add variables
    for i in 1:gen.numberOfJobs
        for j in 1:gen.numberOfMachines
            job_start[i,j] = SeaPearl.IntVar(1, gen.maxTime, "job_start_"*string(i)*"_"*string(j), cpmodel.trailer)
            SeaPearl.addVariable!(cpmodel, job_start[i,j]; branchable=true)  #TODO : double-check this 
            job_end[i,j] = SeaPearl.IntVarViewOffset(job_start[i,j], job_times[i,j], "job_end_"*string(i)*"_"*string(j))
            # SeaPearl.addVariable!(cpmodel, job_end[i,j]; branchable=false)
            # Set maxTime as upper bound to each job_end
            SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqualConstant(job_end[i,j] , gen.maxTime,  cpmodel.trailer))
        end
    end

    ### Constraints ###

    # ensure non-overlaps of the jobs
    for i in 1:gen.numberOfJobs
        SeaPearl.addConstraint!(cpmodel, SeaPearl.Disjunctive(job_start[i, :], job_times[i,:],  cpmodel.trailer))
    end

    # ensure non-overlaps of the machines
    for i in 1:gen.numberOfMachines
        SeaPearl.addConstraint!(cpmodel, SeaPearl.Disjunctive(job_start[:, i], job_times[:, i],  cpmodel.trailer))
    end

    # ensure the job order
    for job in 1:gen.numberOfJobs
        for machine1 in 1:gen.numberOfMachines
            for machine2 in 1:gen.numberOfMachines
                if machine1 < machine2
                    if job_order[job,machine1] < job_order[job,machine2]
                        SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqual(job_end[job, machine1] , job_start[job, machine2],  cpmodel.trailer))
                    else
                        SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqual(job_end[job, machine2] , job_start[job, machine1],  cpmodel.trailer))
                    end
                end
            end
        end
    end

    TotalTime = SeaPearl.IntVar(gen.numberOfMachines, gen.maxTime, "TotalTime", cpmodel.trailer) #THe total time is at least numberOfMachines unit of time considering the way job_times is generated
    SeaPearl.addVariable!(cpmodel, TotalTime; branchable=true)
    for i in 1:gen.numberOfJobs
        for j in 1:gen.numberOfMachines
        SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqual(job_end[i,j], TotalTime, cpmodel.trailer))
        end
    end
    SeaPearl.addObjective!(cpmodel,TotalTime)

    return cpmodel
end

struct JobShopSoftDeadlinesGenerator  <: AbstractModelGenerator
    numberOfMachines   :: Int
    numberOfJobs       :: Int
    maxTime            :: Int
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::GraphColoringGenerator)  
Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose.
"""
function fill_with_generator!(cpmodel::CPModel, gen::JobShopSoftDeadlinesGenerator;  rng::AbstractRNG = MersenneTwister())
    job_times  =  fill(1, gen.numberOfJobs, gen.numberOfMachines) #each task needs to be run at least for 1 unit of time on each machine
    totalTimePerTask = Int(floor(gen.maxTime*0.5))
    #totalTimePerTask = Int(floor(gen.maxTime*(gen.numberOfMachines/gen.numberOfJobs)*0.5))
    for i in 1:gen.numberOfJobs
        for j in 1:totalTimePerTask-gen.numberOfMachines
            job_times[i,rand(rng, 1:j) % gen.numberOfMachines + 1] += 1
        end
    end
    #jobSoftDeadlines = [rand(rng, totalTimePerTask:Int(round(gen.maxTime/2))) for i in 1:gen.numberOfJobs]
    jobSoftDeadlines = [sample(rng, [totalTimePerTask,gen.maxTime], ProbabilityWeights([0.5, 0.5])) for i in 1:gen.numberOfJobs]
    job_order = mapreduce(permutedims, vcat, [randperm(rng, gen.numberOfMachines) for i in 1:gen.numberOfJobs])    #job_order for each task generated using random row-wise permutation.
    cpmodel.adhocInfo = Dict("numberOfMachines" => gen.numberOfMachines, "numberOfJobs" => gen.numberOfJobs, "job_times" => job_times, "job_order" => job_order)

    ### Variable declaration ###    

    # Start/End times for each machine and jobs
    job_start = Matrix{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs, gen.numberOfMachines)
    job_end = Matrix{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs, gen.numberOfMachines)

    # add variables
    for i in 1:gen.numberOfJobs
        for j in 1:gen.numberOfMachines
            job_start[i,j] = SeaPearl.IntVar(1, gen.maxTime, "job_start_"*string(i)*"_"*string(j), cpmodel.trailer)
            SeaPearl.addVariable!(cpmodel, job_start[i,j]; branchable=true)  #TODO : double-check this 
            job_end[i,j] = SeaPearl.IntVarViewOffset(job_start[i,j], job_times[i,j], "job_end_"*string(i)*"_"*string(j))
            # SeaPearl.addVariable!(cpmodel, job_end[i,j]; branchable=false)
            # Set maxTime as upper bound to each job_end
            SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqualConstant(job_end[i,j] , gen.maxTime,  cpmodel.trailer))
        end
    end

    # variables tracing the end time of each job
    job_ending_time = Vector{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs)
    for i in 1:gen.numberOfJobs
        job_ending_time[i] = SeaPearl.IntVar(1, gen.maxTime, "job_ending_time_"*string(i), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, job_ending_time[i]; branchable=false)
        SeaPearl.addConstraint!(cpmodel, SeaPearl.MaximumConstraint(job_end[i,:], job_ending_time[i], cpmodel.trailer))
    end
    
    job_penalties = Vector{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs)
    possible_job_penalties = Vector{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs)
    for i in 1:gen.numberOfJobs
        job_penalties[i] = SeaPearl.IntVar(0, gen.maxTime, "job_penalty_"*string(i), cpmodel.trailer)
        zero_constant = SeaPearl.IntVar(0, 0, "zero_"*string(i), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, zero_constant; branchable=false)
        SeaPearl.addVariable!(cpmodel, job_penalties[i]; branchable=false)
        possible_job_penalties[i] = SeaPearl.IntVarViewOffset(job_ending_time[i], -jobSoftDeadlines[i], "possible_job_penalties"*string(i))
        SeaPearl.addConstraint!(cpmodel, SeaPearl.BinaryMaximumBC(job_penalties[i],possible_job_penalties[i],zero_constant,cpmodel.trailer))
    end

    # Add objective
    objective = SeaPearl.IntVar(0, gen.numberOfJobs*(gen.maxTime-totalTimePerTask), "objective", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, objective, branchable=false)
    objectiveArray = AbstractIntVar[]
    append!(objectiveArray, job_penalties)
    push!(objectiveArray, SeaPearl.IntVarViewOpposite(objective, "-objective"))
    SeaPearl.addConstraint!(cpmodel, SeaPearl.SumToZero(objectiveArray, cpmodel.trailer))
    SeaPearl.addObjective!(cpmodel, objective)
    


    ### Core constraints ###

    # ensure non-overlaps of the jobs
    for i in 1:gen.numberOfJobs
        SeaPearl.addConstraint!(cpmodel, SeaPearl.Disjunctive(job_start[i, :], job_times[i,:],  cpmodel.trailer))
    end

    # ensure non-overlaps of the machines
    for i in 1:gen.numberOfMachines
        SeaPearl.addConstraint!(cpmodel, SeaPearl.Disjunctive(job_start[:, i], job_times[:, i],  cpmodel.trailer))
    end

    # ensure the job order
    for job in 1:gen.numberOfJobs
        for machine1 in 1:gen.numberOfMachines
            for machine2 in 1:gen.numberOfMachines
                if machine1 < machine2
                    if job_order[job,machine1] < job_order[job,machine2]
                        SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqual(job_end[job, machine1] , job_start[job, machine2],  cpmodel.trailer))
                    else
                        SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqual(job_end[job, machine2] , job_start[job, machine1],  cpmodel.trailer))
                    end
                end
            end
        end
    end

    return cpmodel
end

struct JobShopSoftDeadlinesGenerator2  <: AbstractModelGenerator
    numberOfMachines   :: Int
    numberOfJobs       :: Int
    maxTime            :: Int
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::GraphColoringGenerator)  
Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose.
"""
function fill_with_generator!(cpmodel::CPModel, gen::JobShopSoftDeadlinesGenerator2;  rng::AbstractRNG = MersenneTwister())
    job_times  =  fill(1, gen.numberOfJobs, gen.numberOfMachines) #each task needs to be run at least for 1 unit of time on each machine
    totalTimePerTask = Int(floor(gen.maxTime*(gen.numberOfMachines/gen.numberOfJobs)*0.6))
    for i in 1:gen.numberOfJobs
        for j in 1:totalTimePerTask-gen.numberOfMachines
            job_times[i,rand(rng, 1:j) % gen.numberOfMachines + 1] += 1
        end
    end
    #jobSoftDeadlines = [rand(rng, totalTimePerTask:Int(round(gen.maxTime/2))) for i in 1:gen.numberOfJobs]
    jobSoftDeadlines = [sample(rng, [totalTimePerTask,gen.maxTime], ProbabilityWeights([0.5, 0.5])) for i in 1:gen.numberOfJobs]
    job_order = mapreduce(permutedims, vcat, [randperm(rng, gen.numberOfMachines) for i in 1:gen.numberOfJobs])    #job_order for each task generated using random row-wise permutation.
    cpmodel.adhocInfo = Dict("numberOfMachines" => gen.numberOfMachines, "numberOfJobs" => gen.numberOfJobs, "job_times" => job_times, "job_order" => job_order)

    ### Variable declaration ###    

    # Start/End times for each machine and jobs
    job_start = Matrix{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs, gen.numberOfMachines)
    job_end = Matrix{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs, gen.numberOfMachines)

    # add variables
    for i in 1:gen.numberOfJobs
        for j in 1:gen.numberOfMachines
            job_start[i,j] = SeaPearl.IntVar(1, gen.maxTime, "job_start_"*string(i)*"_"*string(j), cpmodel.trailer)
            SeaPearl.addVariable!(cpmodel, job_start[i,j]; branchable=true)  #TODO : double-check this 
            job_end[i,j] = SeaPearl.IntVarViewOffset(job_start[i,j], job_times[i,j], "job_end_"*string(i)*"_"*string(j))
            # SeaPearl.addVariable!(cpmodel, job_end[i,j]; branchable=false)
            # Set maxTime as upper bound to each job_end
            SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqualConstant(job_end[i,j] , gen.maxTime,  cpmodel.trailer))
        end
    end

    # variables tracing the end time of each job
    job_ending_time = Vector{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs)
    for i in 1:gen.numberOfJobs
        job_ending_time[i] = SeaPearl.IntVar(1, gen.maxTime, "job_ending_time_"*string(i), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, job_ending_time[i]; branchable=false)
        SeaPearl.addConstraint!(cpmodel, SeaPearl.MaximumConstraint(job_end[i,:], job_ending_time[i], cpmodel.trailer))
    end
    
    job_penalties = Vector{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs)
    possible_job_penalties = Vector{SeaPearl.AbstractIntVar}(undef, gen.numberOfJobs)
    for i in 1:gen.numberOfJobs
        job_penalties[i] = SeaPearl.IntVar(0, gen.maxTime, "job_penalty_"*string(i), cpmodel.trailer)
        zero_constant = SeaPearl.IntVar(0, 0, "zero_"*string(i), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, zero_constant; branchable=false)
        SeaPearl.addVariable!(cpmodel, job_penalties[i]; branchable=false)
        possible_job_penalties[i] = SeaPearl.IntVarViewOffset(job_ending_time[i], -jobSoftDeadlines[i], "possible_job_penalties"*string(i))
        SeaPearl.addConstraint!(cpmodel, SeaPearl.BinaryMaximumBC(job_penalties[i],possible_job_penalties[i],zero_constant,cpmodel.trailer))
    end

    # Add objective
    objective = SeaPearl.IntVar(0, gen.numberOfJobs*(gen.maxTime-totalTimePerTask), "objective", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, objective, branchable=false)
    objectiveArray = AbstractIntVar[]
    append!(objectiveArray, job_penalties)
    push!(objectiveArray, SeaPearl.IntVarViewOpposite(objective, "-objective"))
    SeaPearl.addConstraint!(cpmodel, SeaPearl.SumToZero(objectiveArray, cpmodel.trailer))
    SeaPearl.addObjective!(cpmodel, objective)
    


    ### Core constraints ###
    # ensure non-overlaps of the machines
    bool_matrix = Array{SeaPearl.AbstractBoolVar,3}(undef, gen.numberOfMachines, gen.numberOfJobs, gen.numberOfJobs)
    for m in 1:gen.numberOfMachines
        for i in 1:gen.numberOfJobs
            for j in (i+1):gen.numberOfJobs
                bool_matrix[m,i,j] = SeaPearl.BoolVar("bool_matrix_"*string(m)*"_"*string(i)*"_"*string(j), cpmodel.trailer)
                bool_matrix[m,j,i] = SeaPearl.BoolVar("bool_matrix_"*string(m)*"_"*string(j)*"_"*string(i), cpmodel.trailer)
                SeaPearl.addVariable!(cpmodel, bool_matrix[m,i,j]; branchable=false)
                SeaPearl.addVariable!(cpmodel, bool_matrix[m,j,i]; branchable=false)
                SeaPearl.addConstraint!(cpmodel, SeaPearl.isLessOrEqual(bool_matrix[m,i,j], job_end[j,m], job_start[i,m],cpmodel.trailer))
                SeaPearl.addConstraint!(cpmodel, SeaPearl.isLessOrEqual(bool_matrix[m,j,i], job_end[i,m], job_start[j,m],cpmodel.trailer))
                SeaPearl.addConstraint!(cpmodel, SeaPearl.BinaryOr(bool_matrix[m,i,j], bool_matrix[m,j,i], cpmodel.trailer))
            end
        end
    end

    # ensure the job order => also ensures non overlap of the jobs on the different machines
    for job in 1:gen.numberOfJobs
        for machine1 in 1:gen.numberOfMachines
            for machine2 in 1:gen.numberOfMachines
                if machine1 < machine2
                    if job_order[job,machine1] < job_order[job,machine2]
                        SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqual(job_end[job, machine1] , job_start[job, machine2],  cpmodel.trailer))
                    else
                        SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqual(job_end[job, machine2] , job_start[job, machine1],  cpmodel.trailer))
                    end
                end
            end
        end
    end

    return cpmodel
end
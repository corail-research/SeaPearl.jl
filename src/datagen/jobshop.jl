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
        totalTimePerTask = Int(floor(gen.maxTime*(gen.numberOfMachines/gen.numberOfJobs)*0.4))
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
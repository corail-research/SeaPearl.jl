
const Solution = Dict{String, Union{Int, Bool, Set{Int}}}

#TODO add documentation for BeforeRestart
# lastPruning: number of deleted variable-value edges
# objectiveDownPruning: min(model.objective.domain)(current) - min(model.objective.domain)(past state)
# objectiveUpPruning: max(model.objective.domain)(current) - max(model.objective.domain)(past state)

mutable struct Statistics
    infeasibleStatusPerVariable             ::Dict{String, Int}
    numberOfNodes                           ::Int
    numberOfSolutions                       ::Int
    numberOfInfeasibleSolutions             ::Int
    numberOfSolutionsBeforeRestart          ::Int
    numberOfInfeasibleSolutionsBeforeRestart::Int
    numberOfNodesBeforeRestart              ::Int
    AccumulatedRewardBeforeReset            ::Float32 # =last_episode_total_reward(lh.agent.trajectory)
    AccumulatedRewardBeforeRestart          ::Float32
    solutions                               ::Vector{Union{Nothing,Solution}}
    nodevisitedpersolution                  ::Vector{Int}
    objectives                              ::Union{Nothing, Vector{Union{Nothing,Int}}}
    lastPruning                             ::Union{Nothing, Int}
    objectiveDownPruning                    ::Union{Nothing, Float32}
    objectiveUpPruning                      ::Union{Nothing, Float32}
    lastVar                                 ::Union{Nothing, AbstractIntVar} #last var on which we branched
    numberOfTimesInvolvedInPropagation      ::Union{Nothing, Dict{Constraint,Int}}
end

mutable struct Limit
    numberOfNodes       ::Union{Int, Nothing}
    numberOfSolutions   ::Union{Int, Nothing}  #the limit can be triggered by set of non-unique solutions
    searchingTime       ::Union{Int, Nothing}
end

"""
    CPModel(trailer::Trailer)
    CPModel()

The structure storing all the informations needed to solve a specific problem and it also stores the solutions.
The CPModel is the center of the solver and evolve during the solving.
The `AbstractStateRepresentation` used by the RL Agent is created from the CPModel.

The CPModel is always created empty and is filled eather by hand by the user (or automatically thanks to written files)
or filled by an `AbstractModelGenerator`.

"""
mutable struct CPModel
    variables               ::Dict{String, AbstractVar}
    branchable              ::Dict{String, Bool}
    branchable_variables    ::Dict{String, AbstractVar}
    constraints             ::Array{Constraint}
    trailer                 ::Trailer
    objective               ::Union{Nothing, AbstractIntVar}
    objectiveBound          ::Union{Nothing, Int}
    statistics              ::Statistics
    limit                   ::Limit
    knownObjective          ::Union{Nothing,Int64}
    adhocInfo               ::Any


    CPModel(trailer) = new(Dict{String, AbstractVar}(), Dict{String, Bool}(), Dict{String, AbstractVar}(), Constraint[], trailer, nothing, nothing, Statistics(Dict{String, Int}(), 0, 0, 0, 0, 0, 0, 0, 0, Solution[],Int[], nothing, nothing, nothing, nothing, nothing, Dict{Constraint, Int}()), Limit(nothing, nothing, nothing), nothing)
end

CPModel() = CPModel(Trailer())

"""
    addVariable!(model::CPModel, x::AbstractVar; branchable=true)

Add a variable to the model, throwing an error if `x`'s id is already in the model.
The `branchable` argument allows you to tell if we will be able to branch on that variable.
"""
function addVariable!(model::CPModel, x::AbstractVar; branchable=true)
    # Ensure the id is unique
    @assert !haskey(model.variables, x.id) "The id of the variable must be unique"

    @assert !branchable || typeof(x) <: Union{AbstractIntVar, AbstractBoolVar} "You can only branch on Boolean and Integer variables"

    model.statistics.infeasibleStatusPerVariable[id(x)]=0
    model.branchable[x.id] = branchable
    model.variables[x.id] = x
    if branchable
        model.branchable_variables[x.id] = x
    end
    
end

"""
    addObjective!(model::CPModel, objective::AbstractVar)

Add an Objective variable to the model. This variable is the variable that needs to be minimized suring the solving.
"""
function addObjective!(model::CPModel, objective::AbstractVar)
    model.objective = objective
    model.statistics.objectives = Int[]  #initialisation of the Array that will contain the score of every solution
end

function addKnownObjective!(model::CPModel, knownObective::Int64)
    model.knownObjective = knownObective
end

function addConstraint!(model::CPModel,constraint::Constraint)
    push!(model.constraints,constraint)
    for var in variablesArray(constraint)
        if haskey(model.branchable, id(var))
            @assert haskey(model.statistics.infeasibleStatusPerVariable, id(var)) "You forget to add the variable $(id(var)) to the model"
            model.statistics.infeasibleStatusPerVariable[id(var)]+=1
        end
    end
    model.statistics.numberOfTimesInvolvedInPropagation[constraint] = 0
end


"""
    function is_branchable(model::CPModel, x::AbstractVar)

Tell if the variable was set as branchable or not.
"""
is_branchable(model::CPModel, x::AbstractVar) = haskey(model.branchable, x.id) && model.branchable[x.id]

"""
    function branchable_variables(model::CPModel)

Return a dict of all branchable variables.
"""
function branchable_variables(model::CPModel)
    to_return = Dict{String, AbstractVar}()
    for x in values(model.variables)
        if is_branchable(model, x)
            to_return[x.id] = x
        end
    end
    to_return
end

"""
    solutionFound(model::CPModel)

Return a boolean, checking whether a solution was found, i.e. every variable is bound.
"""
function solutionFound(model::CPModel)
    for (k, x) in model.variables
        if !isbound(x)
            return false
        end
    end
    return true
end

"""
    triggerFoundSolution!(model::CPModel)

Add the current solution to `model`, and set new constraints for the objective if needed.
"""
function triggerFoundSolution!(model::CPModel)
    @assert solutionFound(model)

    model.statistics.numberOfSolutions += 1
    model.statistics.numberOfSolutionsBeforeRestart += 1

    # Adding the solution
    solution = Solution()
    for (k, x) in model.variables
        solution[k] = assignedValue(x)
    end
    if !(solution in model.statistics.solutions)   #probably not efficient but necessary
        push!(model.statistics.solutions, solution)
        push!(model.statistics.nodevisitedpersolution,model.statistics.numberOfNodes)
        if !isnothing(model.objective)
            @assert !isnothing(model.statistics.objectives)   "did you used SeaPearl.addObjective! to declare your objective function ? "
            push!(model.statistics.objectives, assignedValue(model.objective))
            return :tightenObjective
        end
    end
    return :doNothing
end
"""
    triggerInfeasible!(constraint::Constraint, model::CPModel)

this function increments by one the statistic infeasibleStatusPerVariable for each variable involved in the constraint. infeasibleStatusPerVariable
keeps in track for each variable the number of times the variable was involved in a constraint that led to an infeasible state during a fixpoint. This statistic
is used by the failure-based variable selection heuristic.
"""
function triggerInfeasible!(constraint::Constraint, model::CPModel; isFailureBased::Bool=false)
    if isFailureBased
        for var in variablesArray(constraint)
            if haskey(model.branchable, id(var))
                model.statistics.infeasibleStatusPerVariable[id(var)]+=1
            end
        end
    end

    push!(model.statistics.solutions, nothing)
    push!(model.statistics.nodevisitedpersolution,model.statistics.numberOfNodes)

    if !isnothing(model.objective)
        @assert !isnothing(model.statistics.objectives)   "did you used SeaPearl.addObjective! to declare your objective function ? "
        push!(model.statistics.objectives, nothing)
    end
end


"""
    tightenObjective!(model::CPModel)

Set a new constraint to minimize the objective variable.
"""
function tightenObjective!(model::CPModel)
    model.objectiveBound = assignedValue(model.objective)-1
end

"""
    belowLimits(model::CPModel)

Check if `model`' statistics are still under the limits.
"""
belowLimits(model::CPModel) = belowNodeLimit(model) && belowSolutionLimit(model) && belowTimeLimit(model)
belowNodeLimit(model::CPModel) = isnothing(model.limit.numberOfNodes) || model.statistics.numberOfNodes < model.limit.numberOfNodes
belowSolutionLimit(model::CPModel) = isnothing(model.limit.numberOfSolutions) || model.statistics.numberOfSolutions < model.limit.numberOfSolutions
belowTimeLimit(model::CPModel) = isnothing(model.limit.searchingTime) || peektimer() < model.limit.searchingTime
"""
    Base.isempty(model::CPModel)::Bool

Return a boolean describing if the model is empty or not.
"""
function Base.isempty(model::CPModel)::Bool
    (
        isempty(model.variables)
        && isempty(model.constraints)
        && isempty(model.trailer.prior)
        && isempty(model.trailer.current)
        && isnothing(model.objective)
        && isnothing(model.objectiveBound)
        && isempty(model.statistics.solutions)
        && isempty(model.statistics.nodevisitedpersolution)
        && isempty(model.statistics.infeasibleStatusPerVariable)
        && isnothing(model.statistics.objectives)
        && isnothing(model.statistics.lastPruning)
        && isnothing(model.statistics.lastVar)
        && model.statistics.numberOfNodes == 0
        && model.statistics.numberOfSolutions == 0
        && model.statistics.numberOfInfeasibleSolutions == 0
        && model.statistics.numberOfInfeasibleSolutionsBeforeRestart == 0
        && model.statistics.numberOfSolutionsBeforeRestart == 0
        && model.statistics.numberOfNodesBeforeRestart == 0
        && model.statistics.AccumulatedRewardBeforeReset == 0
        && model.statistics.AccumulatedRewardBeforeRestart == 0
        && isnothing(model.limit.numberOfNodes)
        && isnothing(model.limit.numberOfSolutions)
        && isnothing(model.limit.searchingTime)
        && isnothing(model.knownObjective)
    )
end

"""
    Base.empty!(model::CPModel)

Empty the CPModel.
"""
function Base.empty!(model::CPModel)
    empty!(model.variables)
    empty!(model.branchable_variables)
    empty!(model.branchable)
    empty!(model.constraints)
    empty!(model.trailer.prior)
    empty!(model.trailer.current)
    model.objective = nothing
    model.objectiveBound = nothing
    empty!(model.statistics.solutions)
    empty!(model.statistics.nodevisitedpersolution)
    empty!(model.statistics.infeasibleStatusPerVariable)
    model.statistics.objectives = nothing
    model.statistics.lastPruning = nothing
    model.statistics.lastVar = nothing
    model.statistics.numberOfNodes = 0
    model.statistics.numberOfSolutions = 0
    model.statistics.numberOfInfeasibleSolutions = 0
    model.statistics.numberOfInfeasibleSolutionsBeforeRestart = 0
    model.statistics.numberOfSolutionsBeforeRestart = 0
    model.statistics.numberOfNodesBeforeRestart = 0
    model.statistics.AccumulatedRewardBeforeReset = 0
    model.statistics.AccumulatedRewardBeforeRestart = 0
    model.limit.numberOfNodes = nothing
    model.limit.numberOfSolutions = nothing
    model.limit.searchingTime = nothing
    model.knownObjective = nothing
    model.adhocInfo = nothing
end

"""
    reset_model!(model::CPModel)

Reset a given CPModel instance. Make it possible to reuse the same instance instead of having to
delete the old one and create another one. This is used in `launch_experiment!` in order to be able
to use the same CPModel instance to compare different given heuristics.
"""
function reset_model!(model::CPModel)
    restoreInitialState!(model.trailer)
    model.objectiveBound = nothing
    empty!(model.statistics.solutions)
    empty!(model.statistics.nodevisitedpersolution)
    for (key, value) in model.statistics.infeasibleStatusPerVariable
        model.statistics.infeasibleStatusPerVariable[key]=length(getOnDomainChange(model.variables[key]))  #the degree is reset to the initial value : the number of constraints the variable is involved in.
    end
    if !isnothing(model.objective)
        @assert !isnothing(model.statistics.objectives)   "did you used SeaPearl.addObjective! to declare your objective function ?"
        empty!(model.statistics.objectives)
    end
    model.statistics.lastPruning = nothing
    model.statistics.lastVar = nothing
    model.statistics.numberOfNodes = 0
    model.statistics.numberOfSolutions = 0
    model.statistics.numberOfInfeasibleSolutions = 0
    model.statistics.numberOfInfeasibleSolutionsBeforeRestart = 0
    model.statistics.numberOfSolutionsBeforeRestart = 0
    model.statistics.numberOfNodesBeforeRestart = 0
    model.statistics.AccumulatedRewardBeforeReset = 0
    model.statistics.AccumulatedRewardBeforeRestart = 0  
end
"""
restart_search!(model::CPModel)

Usefull when dealing with restart based search : ILDS or RBS. Reset to zero usefull statistics on the search that can be used to define
the restart criteria.
"""
function restart_search!(model::CPModel)
    restoreInitialState!(model.trailer)
    model.statistics.lastPruning = 0
    model.statistics.lastVar = nothing
    model.statistics.numberOfInfeasibleSolutionsBeforeRestart = 0
    model.statistics.numberOfSolutionsBeforeRestart = 0
    model.statistics.numberOfNodesBeforeRestart = 0
    model.statistics.AccumulatedRewardBeforeRestart = 0

end

"""
    domains_cartesian_product(model::CPModel)

Return the cartesian product of the model variables: |D1|x|D2|x ... x|Dn|
Helps providing insights about what is happening during a search.
"""
function domains_cartesian_product(model::CPModel)
    cart_pdt = 1
    for (id, x) in model.variables
        if typeof(x) <: Union{AbstractIntVar, AbstractBoolVar}
            cart_pdt *= length(x.domain)
        end
    end
    return cart_pdt
end

"""
    nb_boundvariables(model::CPModel)

Return the number of variables that have already been assigned to a value.
Helps providing insights about what is happening during a search.
"""
function nb_boundvariables(model::CPModel)
    nb = 0
    for (id, x) in model.variables
        nb += isbound(x) * 1
    end
    return nb
end

"""
    global_domain_cardinality(model::CPModel)

Returns the sum of the cardinalities of the variable domains.
"""
function global_domain_cardinality(model::CPModel)
    cardinality = 0
    for (id, x) in model.variables
        if isa(x.domain, BoolDomain)
            cardinality += length(x.domain)
            if !isempty(x.children)
                for child in x.children
                    cardinality += length(child.domain)
                end
            end
        elseif isa(x.domain, IntSetDomain)
            cardinality += length(x.domain)
        else
            cardinality += length(x.domain)
            if !isempty(x.children)
                for child in x.children
                    cardinality += length(child.domain)
                end
            end
        end
    end
    return cardinality
end



"""
    updateStatistics!(model::CPModel, pruned)

Called in DFS to update the appropriate statistics used in GeneralReward
"""

function updateStatistics!(model::CPModel, pruned)
    model.statistics.lastPruning = sum(map(x-> length(x[2]),collect(pruned)))
    if !isnothing(model.objective)
        if haskey(pruned,model.objective.id)
            model.statistics.objectiveDownPruning = 0
            model.statistics.objectiveUpPruning = 0
            orderedPrunedValues = sort(pruned[model.objective.id])
            # Last pruning takes all variables except the objective value into consideration
            model.statistics.lastPruning -= length(orderedPrunedValues)
            for val in orderedPrunedValues
                if val <= model.objective.domain.min.value
                    model.statistics.objectiveDownPruning += 1
                elseif val >= model.objective.domain.max.value
                    model.statistics.objectiveUpPruning += 1
                else
                    # Pruning from the middle of the domain of the objective variable
                    model.statistics.objectiveDownPruning += (model.objective.domain.max.value - val)/(model.objective.domain.max.value-model.objective.domain.min.value)
                    model.statistics.objectiveUpPruning += (val - model.objective.domain.min.value)/(model.objective.domain.max.value-model.objective.domain.min.value)
                end
            end
        else
            model.statistics.objectiveDownPruning = 0
            model.statistics.objectiveUpPruning = 0
        end
    end
end
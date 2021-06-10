"""
    SearchMetrics

In order to have insights about what is happening during the search, this structure stores a lot 
of information that describe it. Those informations can eather be used to understand what's happening 
but also to design the rewards that will be given to the agent. 

Do not hesitate to open github issues to ask for other metrics that could be useful for your current research !

Significations:

total_steps::Int64 -> number of removing, assignment & backtrack !
total_states::Int64 -> number of differents states we've been in (removing & assignment only)
total_decisions::Int64
last_backtrack::Int64 -> steps since last backtrack
last_unfeasible::Int64 -> steps since last unfeasible state
last_foundsolution::Int64 -> steps since last found solution
last_feasible::Int64 -> step since a feasible state was reached
backtrack_length::Int64 -> number of steps of the current backtrack or 0
tree_depth::Int64 -> depth in the current research tree
variable_domain_size
new_variable_domain_size
total_boundvariables
new_total_boundvariables
domains_product
new_domains_product
nb_solutions
current_best::Union{Nothing, Int64} -> best solution found so far
true_best::Union{Nothing, Int64} -> eventually true best of the problem
"""

mutable struct SearchMetrics
    total_steps::Int64
    total_states::Int64
    total_decisions::Int64
    total_backtrack::Int64
    last_backtrack::Int64
    last_unfeasible::Int64
    last_foundsolution::Int64
    last_feasible::Int64
    backtrack_length::Int64
    #tree_depth::Int64
    variable_domain_size::Union{Nothing, Int64}
    new_variable_domain_size::Union{Nothing, Int64}
    total_boundvariables::Union{Nothing, Int64}
    new_total_boundvariables::Union{Nothing, Int64}
    domains_product::Union{Nothing, Int64}
    new_domains_product::Union{Nothing, Int64}
    nb_solutions::Int64
    current_best::Union{Nothing, Int64}
    true_best::Union{Nothing, Int64}
end

SearchMetrics() = SearchMetrics(0, 1, 0, 0, 0, 0, 0, 0, 0, nothing, nothing, 0, nothing, 0, nothing, 0, nothing, nothing)

"""
    SearchMetrics(model::CPModel)

Create a SearchMetrics instance initialized thanks to a CPModel.
"""
function SearchMetrics(model::CPModel)
    total_boundvariables = nb_boundvariables(model)
    domains_product = domains_cartesian_product(model)
    SearchMetrics(0, 1, 0, 0, 0, 0, 0, 0, 0, nothing, nothing, total_boundvariables, nothing, domains_product, nothing, 0, nothing, nothing)
end

"""
    set_metrics!(::StepPhase, search_metrics::SearchMetrics, model::CPModel, symbol::Union{Nothing, Symbol}, x::Union{Nothing, AbstractIntVar})

Set the search metrics thanks to informations from the CPModel and the current status during the StepPhase.
"""
function set_metrics!(::Type{StepPhase}, search_metrics::SearchMetrics, model::CPModel, symbol::Union{Nothing, Symbol} )
    search_metrics.total_steps += 1
    search_metrics.total_states += 1
    search_metrics.last_backtrack += 1
    search_metrics.last_unfeasible += 1
    search_metrics.last_foundsolution += 1
    search_metrics.last_feasible += 1

    if symbol == :Infeasible
        search_metrics.last_unfeasible = 1
        search_metrics.backtrack_length = 0
        #search_metrics.tree_depth += 1
    elseif symbol == :FoundSolution
        search_metrics.total_steps -= 1
        search_metrics.total_states -= 1
        search_metrics.last_backtrack -= 1
        search_metrics.last_unfeasible -= 1
        search_metrics.last_foundsolution = 1
        search_metrics.last_feasible = 1
        search_metrics.backtrack_length = 0
        search_metrics.nb_solutions += 1
    elseif symbol == :Feasible 
        search_metrics.last_feasible = 1
        search_metrics.backtrack_length = 0
        #search_metrics.tree_depth += 1
    elseif symbol == :BackTracking
        search_metrics.total_states -= 1
        search_metrics.total_backtrack += 1
        search_metrics.last_backtrack = 1
        search_metrics.backtrack_length += 1
        #search_metrics.tree_depth -= 1
    end
    
    if !isnothing(model.objectiveBound)
        search_metrics.current_best = model.objectiveBound + 1
    end

    search_metrics.total_boundvariables = nb_boundvariables(model)
    # couldn't it be improved with CPModification ? 
    search_metrics.domains_product = domains_cartesian_product(model)

    nothing
end


"""
    set_metrics!(::DecisionPhase, search_metrics::SearchMetrics, model::CPModel, symbol::Union{Nothing, Symbol}, x::Union{Nothing, AbstractIntVar})

Set the search metrics thanks to informations from the CPModel and the current status during the DecisionPhase
"""
function set_metrics!(::Type{DecisionPhase}, search_metrics::SearchMetrics, model::CPModel, x::Union{Nothing, AbstractIntVar})
    search_metrics.total_decisions += 1
    search_metrics.domains_product = search_metrics.new_domains_product
    search_metrics.new_domains_product = domains_cartesian_product(model)
    search_metrics.total_boundvariables = search_metrics.new_total_boundvariables
    search_metrics.new_total_boundvariables = nb_boundvariables(model)
    search_metrics.variable_domain_size = search_metrics.new_variable_domain_size
    search_metrics.new_variable_domain_size = length(x.domain)
end
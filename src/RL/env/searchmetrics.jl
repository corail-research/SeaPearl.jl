"""
    SearchMetrics

Significations:

total_steps::Int64 -> number of removing, assignment & backtrack !
total_states::Int64 -> number of differents states we've been in (removing & assignment only)
last_backtrack::Int64 -> steps since last backtrack
last_unfeasible::Int64 -> steps since last unfeasible state
last_foundsolution::Int64 -> steps since last found solution
last_feasible::Int64 -> step since a feasible state was reached
backtrack_length::Int64 -> number of steps of the current backtrack or 0
tree_depth::Int64 -> depth in the current research tree
current_best::Union{Nothing, Int64} -> best solution found so far
true_best::Union{Nothing, Int64} -> eventually true best of the problem

One of the roles of the env is to manage the reward which is going to be given. In the simplest schema, it is
just a simple reward which is given as a field of RLEnv. To make things more complete and flexible to the user, 
we add a SearchMetrics which will help design interesting rewards.
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
    total_boundvariables::Int64
    domains_product::Int64
    nb_solutions::Int64
    current_best::Union{Nothing, Int64}
    true_best::Union{Nothing, Int64}
end

SearchMetrics() = SearchMetrics(0, 1, 0, 0, 0, 0, 0, 0, 0, nothing, 0, 0, 0, nothing, nothing)

"""
    SearchMetrics(model::CPModel)

Create a SearchMetrics instance initialized thanks to a CPModel.
"""
function SearchMetrics(model::CPModel)
    total_boundvariables = nb_boundvariables(model)
    domains_product = domains_cartesian_product(model)
    SearchMetrics(0, 1, 0, 0, 0, 0, 0, 0, 0, nothing, total_boundvariables, domains_product, 0, nothing, nothing)
end

"""
    set_metrics!(search_metrics::SearchMetrics, model::CPModel, symbol::Union{Nothing, Symbol})

Set the search metrics thanks to informations from the CPModel and the current status. 
Can be useful for insights or for reward engineering.
"""
function set_metrics!(search_metrics::SearchMetrics, model::CPModel, symbol::Union{Nothing, Symbol})
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
        search_metrics.total_decisions += 1 # that's cheating - change it 
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
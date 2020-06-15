using Distributions

"""
    fill_with_coloring!(cpmodel::CPModel, nb_node, density, centrality)::CPModel    

Create a filled CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose ! Density should be more than 1.
"""
function fill_with_coloring!(cpmodel::CPModel, nb_nodes::Int64, density::Number)
    nb_edges = floor(Int64, density * nb_nodes)

    # create variables
    x = CPRL.IntVar[]
    for i in 1:nb_nodes
        push!(x, CPRL.IntVar(1, nb_nodes, string(i), cpmodel.trailer))
        addVariable!(cpmodel, last(x))
    end
    @assert nb_edges >= nb_nodes - 1
    connexions = [1 for i in 1:nb_nodes]
    # create Geometric distribution
    p = 2 / nb_nodes
    distr = Truncated(Geometric(p), 0, nb_nodes)
    new_connexions = rand(distr, nb_edges - nb_nodes)
    for new_co in new_connexions
        connexions[convert(Int64, new_co)] += 1
    end

    # should make sure that every node has less than nb_nodes - 1 connexions

    # edge constraints
    for i in 1:length(connexions)
        neighbors = sample([j for j in 1:length(connexions) if j != i && connexions[i] > 0], connexions[i], replace=false)
        for j in neighbors
            push!(cpmodel.constraints, CPRL.NotEqual(x[i], x[j], cpmodel.trailer))
        end
    end

    ### Objective ###
    numberOfColors = CPRL.IntVar(0, nb_nodes, "numberOfColors", cpmodel.trailer)
    CPRL.addVariable!(cpmodel, numberOfColors)
    for var in x
        push!(cpmodel.constraints, CPRL.LessOrEqual(var, numberOfColors, cpmodel.trailer))
    end
    cpmodel.objective = numberOfColors

    nothing
end

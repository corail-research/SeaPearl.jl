using StatsBase: sample

"""KepGenerator <: AbstractModelGenerator
Generator for the kidney exchange problem: https://hal.science/hal-01798850/document

"""
struct KepGenerator <: AbstractModelGenerator
    nb_nodes::Int # probability of creating an edge between i and j
    density::Real # number of pairs of the instance
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::KepGenerator; rng::AbstractRNG = MersenneTwister())   

Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose!

The decision matrix `x` is the adjacent matrix of the graph (i.e. the instance). 
x[i, j] is branchable => pair i can receive a kidney from pair j
x[i, j] is not branchable => pair i can not receive a kidney from pair j

The generator ensure that all pairs have at least one incoming arc and one outgoing arc (i.e. at least one branchable variable per row and column).
For this we first place one branchable variable in each line of the matrix with a different column index each time.
Then, the remaining edges are assigned randomly between the non-asssigned elements of the decision matrix. For reference, see https://hal.science/hal-01798850/document
"""
function fill_with_generator!(model, gen::KepGenerator; rng::AbstractRNG=MersenneTwister())
    density = gen.density
    nb_nodes = gen.nb_nodes
    total_edges = round(Int, nb_nodes * nb_nodes * density)
    @assert total_edges > nb_nodes "density too low to ensure that all pairs have at least one incoming arc and one outgoing arc"

    ### Instance ###
    # ensure that all pairs have at least one in edge and one out edge 
    indexes = [(i, j) for i = 1:nb_nodes for j = 1:nb_nodes]
    permutation = shuffle(rng, [i for i = 1:nb_nodes]) # permutation[i] = j => x[i, j] is branchable
    flat_index_required_branchable = [permutation[i] + (i - 1) * nb_nodes for i in 1:nb_nodes]
    index_branchable = [] # Array that will containing the indexes (as tuples) of the branchable variables
    for i in reverse(flat_index_required_branchable)
        push!(index_branchable, splice!(indexes, i))
    end

    # the remaining edges are assigned randomly between the non-asssigned elements of the decision matrix
    nb_unassigned_edges = total_edges - nb_nodes
    append!(index_branchable, sample(rng, indexes, nb_unassigned_edges, replace=false))

    ### Variables ###
    x = Matrix{SeaPearl.AbstractIntVar}(undef, nb_nodes, nb_nodes)
    minus_x = Matrix{SeaPearl.AbstractIntVar}(undef, nb_nodes, nb_nodes)

    for i = 1:nb_nodes
        for j = 1:nb_nodes
            if (i, j) in index_branchable
                x[i, j] = SeaPearl.IntVar(0, 1, "x_" * string(i) * "_" * string(j), model.trailer)
                SeaPearl.addVariable!(model, x[i, j]; branchable=true)
                minus_x[i, j] = SeaPearl.IntVarViewOpposite(x[i, j], "-x_" * string(i) * "_" * string(j))
            else
                x[i, j] = SeaPearl.IntVar(0, 0, "x_" * string(i) * "_" * string(j), model.trailer)
                SeaPearl.addVariable!(model, x[i, j]; branchable=false)
                minus_x[i, j] = SeaPearl.IntVarViewOpposite(x[i, j], "-x_" * string(i) * "_" * string(j))
            end
        end
    end

    ### Constraints ###
    for i = 1:nb_nodes
        SeaPearl.addConstraint!(model, SeaPearl.SumLessThan(x[i, :], 1, model.trailer)) #Check that any pair receives more than 1 kidney
        SeaPearl.addConstraint!(model, SeaPearl.SumLessThan(x[:, i], 1, model.trailer)) #Check that any pair gives more than 1 kidney
        SeaPearl.addConstraint!(model, SeaPearl.SumToZero(hcat(x[:, i], minus_x[i, :]), model.trailer)) #Check that for each pair: give a kidney <=> receive a kidney
    end

    ### Objective ###
    #SeaPearl's solver minimize the objective variable, so we use minusNumberOfExchanges in order to maximize the number of exchanges
    minusNumberOfExchanges = SeaPearl.IntVar(-nb_nodes, 0, "minusNumberOfExchanges", model.trailer)
    SeaPearl.addVariable!(model, minusNumberOfExchanges; branchable=false)
    vars = SeaPearl.AbstractIntVar[]

    #Concatenate all values of x and minusNumberOfExchanges
    for i in 1:nb_nodes
        vars = cat(vars, x[i, :]; dims=1)
    end
    push!(vars, minusNumberOfExchanges)

    #minusNumberOfExchanges will take the necessary value to compensate the occurences of "1" in x
    objective = SeaPearl.SumToZero(vars, model.trailer)
    SeaPearl.addConstraint!(model, objective)
    SeaPearl.addObjective!(model, minusNumberOfExchanges)
end
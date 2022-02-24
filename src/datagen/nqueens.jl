#Defining a generator does not make a lot of sense, since for a chosen board_size, there is only one possible instance.
#We define it to se how much our agent can learn on a single instance.

struct NQueensGenerator <: AbstractModelGenerator
    board_size::Int
    #density::Real
    function NQueensGenerator(board_size)
        @assert board_size > 1
        new(board_size)
    end
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::GraphColoringGenerator)
Fill a CPModel with the variables and constraints generated. We fill it directly instead of
creating temporary files for efficiency purpose.

A seed must be specified by the user to generate a specific instance. As long as Random.seed!(seed) is called at the beginning of the function, every random-based operations with be deterministic. Caution : this is not the seed that must be specified in order to generate a same set of evaluation instances across experiment, in that case, the user must call Random.seed! only once, at the beginning of the experiment. 

This generator create graps for the NQueens problem.

"""
function fill_with_generator!(cpmodel::CPModel, gen::NQueensGenerator; rng::Union{Nothing,AbstractRNG} = nothing)
    cpmodel.limit.numberOfSolutions = 1

    #density = gen.density
    board_size = gen.board_size

    #nb_edges = floor(Int64, density * nb_nodes)

    rows = Vector{SeaPearl.AbstractIntVar}(undef, board_size)
    for i = 1:board_size
        rows[i] = SeaPearl.IntVar(1, board_size, "row_"*string(i), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, rows[i]; branchable=true)
    end

    rows_plus = Vector{SeaPearl.AbstractIntVar}(undef, board_size)
    for i = 1:board_size
        rows_plus[i] = SeaPearl.IntVarViewOffset(rows[i], i, rows[i].id*"+"*string(i))
        #SeaPearl.addVariable!(model, rows_plus[i]; branchable=false)
    end

    rows_minus = Vector{SeaPearl.AbstractIntVar}(undef, board_size)
    for i = 1:board_size
        rows_minus[i] = SeaPearl.IntVarViewOffset(rows[i], -i, rows[i].id*"-"*string(i))
        #SeaPearl.addVariable!(model, rows_minus[i]; branchable=false)
    end

    SeaPearl.addConstraint!(cpmodel, SeaPearl.AllDifferent(rows, cpmodel.trailer))
    SeaPearl.addConstraint!(cpmodel, SeaPearl.AllDifferent(rows_plus, cpmodel.trailer))
    SeaPearl.addConstraint!(cpmodel, SeaPearl.AllDifferent(rows_minus, cpmodel.trailer))
    return nothing
    #return model
end

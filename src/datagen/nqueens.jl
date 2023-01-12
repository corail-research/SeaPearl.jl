#Defining a generator does not make a lot of sense, since for a chosen board_size, there is only one possible instance.
#We define it to se how much our agent can learn on a single instance.

"""NQueensGenerator <: AbstractModelGenerator
Generator for the N-queens problem: https://en.wikipedia.org/wiki/Eight_queens_puzzle
"""
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

Rng is a random number generator used to ensure experiment reproductibility accross devices. It is often set at the beginning of an experiment to generate deterministic training samples. 


This generator create graps for the NQueens problem.

"""
function fill_with_generator!(cpmodel::CPModel, gen::NQueensGenerator; rng::AbstractRNG=MersenneTwister())
    cpmodel.limit.numberOfSolutions = 1

    #density = gen.density
    board_size = gen.board_size

    #nb_edges = floor(Int64, density * nb_nodes)

    rows = Vector{SeaPearl.AbstractIntVar}(undef, board_size)
    for i = 1:board_size
        rows[i] = SeaPearl.IntVar(1, board_size, "row_" * string(i), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, rows[i]; branchable=true)
    end

    rows_plus = Vector{SeaPearl.AbstractIntVar}(undef, board_size)
    for i = 1:board_size
        rows_plus[i] = SeaPearl.IntVarViewOffset(rows[i], i, rows[i].id * "+" * string(i))
        #SeaPearl.addVariable!(model, rows_plus[i]; branchable=false)
    end

    rows_minus = Vector{SeaPearl.AbstractIntVar}(undef, board_size)
    for i = 1:board_size
        rows_minus[i] = SeaPearl.IntVarViewOffset(rows[i], -i, rows[i].id * "-" * string(i))
        #SeaPearl.addVariable!(model, rows_minus[i]; branchable=false)
    end

    SeaPearl.addConstraint!(cpmodel, SeaPearl.AllDifferent(rows, cpmodel.trailer))
    SeaPearl.addConstraint!(cpmodel, SeaPearl.AllDifferent(rows_plus, cpmodel.trailer))
    SeaPearl.addConstraint!(cpmodel, SeaPearl.AllDifferent(rows_minus, cpmodel.trailer))
    return nothing
    #return model
end

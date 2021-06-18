struct LatinGenerator <: AbstractModelGenerator
    N::Int
    p::Float64
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::GraphColoringGenerator)
Fill a CPModel with the variables and constraints generated. We fill it directly instead of
creating temporary files for efficiency purpose.

This generator create graps for the NQueens problem.

"""

function proper_move(A::Matrix{Int},x::Int,y::Int,z::Int,v::Int)
    z2 = A[x,y]
    if z2==v
        A[x,y]=z
    else
        y2 = rand(findall(k->k==v, A[x,:]))
        x2 = rand(findall(k->k==v, A[:,y]))
        A[x,y] = z
        A[x,y2]= z2
        A[x2,y]= z2
        proper_move(A,x2,y2,v,z2)
    end
end


function fill_with_generator!(cpmodel::CPModel, gen::LatinGenerator; seed=nothing)
    N = gen.N
    p = gen.p
    cpmodel.limit.numberOfSolutions = 1
    A = Matrix{Int}(undef,N,N)
    for i in 1:N A[i,:]= [(i+j-2)%N + 1 for j in 1:N] end
    if !isnothing(seed)
        Random.seed!(seed)
    end
    for i in 1:N^3
        x,y,z = rand(1:N,3)
        proper_move(A,x,y,z,z)
    end

    n = floor(Int,p*N^2)
    indicies = shuffle(1:N^2)[1:n]
    for x in indicies
        i = div(x-1,N) + 1
        j = (x-1)%N + 1
        A[i,j] = 0
    end

    puzzle = Matrix{SeaPearl.AbstractIntVar}(undef, N,N)
    for i = 1:N
        for j in 1:N
            puzzle[i,j] = SeaPearl.IntVar(1, N, "puzzle_"*string(i)*","*string(j), cpmodel.trailer)
            SeaPearl.addVariable!(cpmodel, puzzle[i,j]; branchable=true)
            if A[i,j]>0 push!(cpmodel.constraints,SeaPearl.EqualConstant(puzzle[i,j], A[i,j], cpmodel.trailer)) end
        end
    end
    for i in 1:N
        push!(cpmodel.constraints, SeaPearl.AllDifferent(puzzle[i,:], cpmodel.trailer))
        push!(cpmodel.constraints, SeaPearl.AllDifferent(puzzle[:,i], cpmodel.trailer))
    end
    return nothing
end

#We generate random eternity2 feasible puzzles

#First, we create the pieces, randomly simpling the color of the edges. Then, we shuffle the pieces

struct Eternity2Generator <: AbstractModelGenerator
    n::Int
    m::Int
    k::Int
end


"""
    fill_with_generator!(cpmodel::CPModel, gen::GraphColoringGenerator)
Fill a CPModel with the variables and constraints generated. We fill it directly instead of
creating temporary files for efficiency purpose.

This generator create graps for the Eternity2 problem.
"""

"""
function fill_with_generator!(cpmodel::CPModel, gen::Eternity2Generator; seed=123)
    cpmodel.limit.numberOfSolutions = 1
    if !isnothing(seed)
        Random.seed!(seed)
    end
    rng = MersenneTwister(seed)
    n=gen.n
    m=gen.m
    k=gen.k
    colors=1:k

    src_v = Matrix{Int}(undef,n,m+1) #horizontal edges
    src_h = Matrix{Int}(undef,n+1,m) #vertical edges
    fill!(src_h,0)
    fill!(src_v,0)

    shuff = shuffle(rng,1:n*m)

    for i in 2:n
        for j in 1:m
            src_h[i,j]=rand(rng,colors)
        end
    end

    for i in 1:n
        for j in 2:m
            src_v[i,j]=rand(rng,colors)
        end
    end

    pieces = Matrix{Int}(undef, n*m, 4)

    for i = 1:n
        for j = 1:m
            pieces[shuff[(i-1)*m + j],1] = src_h[i,j]
            pieces[shuff[(i-1)*m + j],2] = src_v[i,j+1]
            pieces[shuff[(i-1)*m + j],3] = src_h[i+1,j]
            pieces[shuff[(i-1)*m + j],4] = src_v[i,j]
        end
    end

    table = Matrix{Int}(undef, 6, 4*n*m) #n*m pieces with four different orientations, 6 for orientation  + u + r + d + l + id

    for i = 1:n*m
        for k = 1:4
            table[1,4*(i-1) + k] = i
            table[6,4*(i-1) + k] = 4*(i-1) + k
            for j = 2:5
                table[j,4*(i-1) + k] = pieces[i, (j+k+1)%4+1]
            end
        end
    end

    id = Matrix{SeaPearl.AbstractIntVar}(undef, n, m)
    u = Matrix{SeaPearl.AbstractIntVar}(undef, n, m)#up
    r = Matrix{SeaPearl.AbstractIntVar}(undef, n, m)#right
    d = Matrix{SeaPearl.AbstractIntVar}(undef, n, m)#down
    l = Matrix{SeaPearl.AbstractIntVar}(undef, n, m)#left

    src_v = Matrix{SeaPearl.AbstractIntVar}(undef,n,m+1) #vertical edges
    src_h = Matrix{SeaPearl.AbstractIntVar}(undef,n+1,m) #horizontal edges
    orientation = Matrix{SeaPearl.AbstractIntVar}(undef, n,m)

    for i = 1:n
        src_v[i,m+1] = SeaPearl.IntVar(0, k, "src_v"*string(i)*string(m+1), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, src_v[i,m+1]; branchable=false)
    end
    for j =1:m
        src_h[n+1,j] = SeaPearl.IntVar(0, k, "src_h"*string(n+1)*string(j), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, src_h[n+1,j]; branchable=false)
    end

    for i = 1:n, j=1:m
        orientation[i,j] = SeaPearl.IntVar(1, 4*n*m, "orientation_"*string(i)*string(j), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, orientation[i,j]; branchable=true)
        id[i,j] = SeaPearl.IntVar(1, n*m, "id_"*string(i)*string(j), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, id[i,j]; branchable=false)
        src_v[i,j] = SeaPearl.IntVar(0, k, "src_v"*string(i)*string(j), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, src_v[i,j]; branchable=false)
        src_h[i,j] = SeaPearl.IntVar(0, k, "src_h"*string(i)*string(j), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, src_h[i,j]; branchable=false)
    end

    for i = 1:n, j=1:m
        u[i,j] = src_h[i,j]
        d[i,j] = src_h[i+1,j]
        l[i,j] = src_v[i,j]
        r[i,j] = src_v[i,j+1]

        vars = SeaPearl.AbstractIntVar[id[i,j], u[i,j], r[i,j],d[i,j], l[i,j], orientation[i,j]]
        SeaPearl.addConstraint!(cpmodel, SeaPearl.TableConstraint(vars, table, cpmodel.trailer))

        if (j==m) SeaPearl.addConstraint!(cpmodel, SeaPearl.EqualConstant(r[i,j], 0, cpmodel.trailer)) end
        if (j==1) SeaPearl.addConstraint!(cpmodel, SeaPearl.EqualConstant(l[i,j], 0, cpmodel.trailer)) end
        if (i==1) SeaPearl.addConstraint!(cpmodel, SeaPearl.EqualConstant(u[i,j], 0, cpmodel.trailer)) end
        if (i==n) SeaPearl.addConstraint!(cpmodel, SeaPearl.EqualConstant(d[i,j], 0, cpmodel.trailer)) end
    end

    return nothing
end
"""


function fill_with_generator!(cpmodel::CPModel, gen::Eternity2Generator; seed=123)
    cpmodel.limit.numberOfSolutions = 1
    if !isnothing(seed)
        Random.seed!(seed)
    end
    rng = MersenneTwister(seed)
    n=gen.n
    m=gen.m
    k=gen.k
    colors=1:k

    table = Matrix{Int}(undef, 5, 4*n*m)

    src_v = Matrix{Int}(undef,n,m+1) #horizontal edges
    src_h = Matrix{Int}(undef,n+1,m) #vertical edges
    fill!(src_h,0)
    fill!(src_v,0)

    shuff = shuffle(rng,1:n*m)

    for i in 2:n
        for j in 1:m
            src_h[i,j]=rand(rng,colors)
        end
    end

    for i in 1:n
        for j in 2:m
            src_v[i,j]=rand(rng,colors)
        end
    end
    pieces = Matrix{Int}(undef, n*m, 4)

    for i = 1:n
        for j = 1:m
            pieces[shuff[(i-1)*m + j],1] = src_h[i,j]
            pieces[shuff[(i-1)*m + j],2] = src_v[i,j+1]
            pieces[shuff[(i-1)*m + j],3] = src_h[i+1,j]
            pieces[shuff[(i-1)*m + j],4] = src_v[i,j]
        end
    end

    for i = 1:n*m
        for k = 1:4
            table[1,4*(i-1) + k] = i
            for j = 2:5
                table[j,4*(i-1) + k] = pieces[i, (j+k+1)%4+1]
            end
        end
    end

    id = Matrix{SeaPearl.AbstractIntVar}(undef, n, m)
    u = Matrix{SeaPearl.AbstractIntVar}(undef, n, m)#up
    r = Matrix{SeaPearl.AbstractIntVar}(undef, n, m)#right
    d = Matrix{SeaPearl.AbstractIntVar}(undef, n, m)#down
    l = Matrix{SeaPearl.AbstractIntVar}(undef, n, m)#left
    src_v = Matrix{SeaPearl.AbstractIntVar}(undef,n,m+1) #horizontal edges
    src_h = Matrix{SeaPearl.AbstractIntVar}(undef,n+1,m) #vertical edges

    for i = 1:n
        src_v[i,m+1] = SeaPearl.IntVar(0, k, "src_v"*string(i)*string(m+1), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, src_v[i,m+1]; branchable=false)
    end
    for j =1:m
        src_h[n+1,j] = SeaPearl.IntVar(0, k, "src_h"*string(n+1)*string(j), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, src_h[n+1,j]; branchable=false)
    end


    for i = 1:n, j=1:m
        id[i,j] = SeaPearl.IntVar(1, n*m, "id_"*string(i)*string(j), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, id[i,j]; branchable=true)
        src_v[i,j] = SeaPearl.IntVar(0, k, "src_v"*string(i)*string(j), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, src_v[i,j]; branchable=false)
        src_h[i,j] = SeaPearl.IntVar(0, k, "src_h"*string(i)*string(j), cpmodel.trailer)
        SeaPearl.addVariable!(cpmodel, src_h[i,j]; branchable=false)
    end

    for i = 1:n, j=1:m
        u[i,j] = src_h[i,j]
        d[i,j] = src_h[i+1,j]
        l[i,j] = src_v[i,j]
        r[i,j] = src_v[i,j+1]

        vars = SeaPearl.AbstractIntVar[id[i,j], u[i,j], r[i,j],d[i,j], l[i,j]]
        SeaPearl.addConstraint!(cpmodel, SeaPearl.TableConstraint(vars, table, cpmodel.trailer))

        if (j==m) SeaPearl.addConstraint!(cpmodel, SeaPearl.EqualConstant(r[i,j], 0, cpmodel.trailer)) end
        if (j==1) SeaPearl.addConstraint!(cpmodel, SeaPearl.EqualConstant(l[i,j], 0, cpmodel.trailer)) end
        if (i==1) SeaPearl.addConstraint!(cpmodel, SeaPearl.EqualConstant(u[i,j], 0, cpmodel.trailer)) end
        if (i==n) SeaPearl.addConstraint!(cpmodel, SeaPearl.EqualConstant(d[i,j], 0, cpmodel.trailer)) end
    end

    #breaking some symmetries

    #if count(==(2),count(==(0),pieces,dims=2))==4
        #index = findfirst(==(2),vec(count(==(0),pieces,dims=2)))
        #SeaPearl.addConstraint!(model,SeaPearl.EqualConstant(id[1,1], index, trailer))
        #SeaPearl.assign!(id[1,1].domain, index)
    #end


    SeaPearl.addConstraint!(cpmodel, SeaPearl.AllDifferent(id, cpmodel.trailer))
    return nothing

end

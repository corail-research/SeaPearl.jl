"""
    Element2D(matrix::Array{Int, 2}, x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, SeaPearl.trailer)

Element2D constraint, states that `matrix[x, y] == z`
"""
struct Element2D <: Constraint
    matrix::Array{Int, 2}
    x::AbstractIntVar
    y::AbstractIntVar
    z::AbstractIntVar
    n_rows_sup::Array{StateObject{Int}, 1}
    n_cols_sup::Array{StateObject{Int}, 1}
    low::StateObject{Int}
    up::StateObject{Int}
    xyz::Array{Tuple{Int, Int, Int}, 1}
    active::StateObject{Bool}

    function Element2D(matrix::Array{Int, 2}, x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)
        n, m = size(matrix)
        xyz = Array{Tuple{Int, Int, Int}, 1}()
        for i in 1:n
            for j in 1:m
                push!(xyz, (i, j, matrix[i, j]))
            end
        end
        sort!(xyz, by = xyz -> xyz[3])
        low = StateObject{Int}(1, trailer)
        up = StateObject{Int}(n*m, trailer)
        n_cols_sup = [StateObject{Int}(n, trailer) for i in 1:m]
        n_rows_sup = [StateObject{Int}(m, trailer) for i in 1:n]

        constraint = new(matrix, x, y, z, n_rows_sup, n_cols_sup, low, up, xyz, StateObject{Bool}(true, trailer))
        # we should prune below 1 and above (n resp. m) or add an offset
        for xi in [x, y, z]
            addOnDomainChange!(xi, constraint)
        end
        return constraint
    end
end

"""
    update_support_and_prune!(constraint::Element2D, xyz::Array{Tuple{Int, Int, Int}, 1}, lost_position::Int)

Supports are associated to x and y 's domains. Each possible value of x & y can be associated with n number of possible
values of z. If this number n equal 0, the value associated is pruned.

This function basically handle the increment, prune domains when necessary and retrieve the pruned values.
"""
function update_support_and_prune!(constraint::Element2D, xyz::Array{Tuple{Int, Int, Int}, 1}, lost_position::Int)
    setValue!(constraint.n_rows_sup[xyz[lost_position][1]], constraint.n_rows_sup[xyz[lost_position][1]].value - 1)
    setValue!(constraint.n_cols_sup[xyz[lost_position][2]], constraint.n_cols_sup[xyz[lost_position][2]].value - 1)
    prunedX, prunedY = [], []
    if constraint.n_rows_sup[xyz[lost_position][1]].value == 0
        prunedX = remove!(constraint.x.domain, xyz[lost_position][1])
    end
    if constraint.n_cols_sup[xyz[lost_position][2]].value == 0
        prunedY = remove!(constraint.y.domain, xyz[lost_position][2])
    end
    return prunedX, prunedY
end

"""
    propagate!(constraint::Element2D, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`Element2D` propagation function.

Supports (n_cols_sup & n_rows_sup) are the number of possible z values that
are in a row or column. Once a support reaches 0, the value corresponding to the index cannot be taken by
the corresponding variable.
x = [1, 2, 3]
y = [1, 2, 3]
z = [6, 7]
          | 1 | 2 | 3 | n_rows_sup
        --------------
        1 | 3   4   2    0
        2 | 6   7   1    2
        3 | 7   5   1    1

n_cols_sup  2   1   0

Here, the value 3 can be pruned from y and the value 1 can be pruned from x.

Only the lowest and the highest values of z are pruned when they are not in the matrix.
(it's be for performance reason, this implemention is inspired by miniCP)

It'd be interesting to try to benchmark with a propagation function which also pruned
non extreme values to make sure it's not better.

"""
function propagate!(constraint::Element2D, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    # get useful variables
    low = constraint.low.value
    up = constraint.up.value
    z_min = minimum(constraint.z.domain)
    z_max = maximum(constraint.z.domain)
    xyz = constraint.xyz
    n, m = size(constraint.matrix)

    # make sure x, y are valid indexes of matrix
    prunedX = vcat(removeBelow!(constraint.x.domain, 1), removeAbove!(constraint.x.domain, n))
    prunedY = vcat(removeBelow!(constraint.y.domain, 1), removeAbove!(constraint.y.domain, m))
    if !isempty(prunedX)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
    end
    if !isempty(prunedY)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
    end

    # update the supports of the cols and the rows and prune X or Y if some supports equal 0
    # lower bound
    while xyz[low][3] < z_min || !(xyz[low][1] in constraint.x.domain) || !(xyz[low][2] in constraint.y.domain)
        prunedX, prunedY = update_support_and_prune!(constraint, xyz, low)
        if !isempty(prunedX)
            addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
            triggerDomainChange!(toPropagate, constraint.x)
        end
        if !isempty(prunedY)
            addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
            triggerDomainChange!(toPropagate, constraint.y)
        end
        low += 1
        # @assert low <= up
        if low > up
            return false
        end
    end
    # upper bound
    while xyz[up][3] > z_max || !(xyz[up][1] in constraint.x.domain) || !(xyz[up][2] in constraint.y.domain)
        prunedX, prunedY = update_support_and_prune!(constraint, xyz, up)
        if !isempty(prunedX)
            addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
            triggerDomainChange!(toPropagate, constraint.x)
        end
        if !isempty(prunedY)
            addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
            triggerDomainChange!(toPropagate, constraint.y)
        end
        up -= 1
        # @assert low <= up
        if low > up
            return false
        end
    end

    # try to prune lower or upper values of z's domain
    prunedZ = vcat(removeBelow!(constraint.z.domain, xyz[low][3]), removeAbove!(constraint.z.domain, xyz[up][3]))
    if !isempty(prunedZ)
        addToPrunedDomains!(prunedDomains, constraint.z, prunedZ)
        triggerDomainChange!(toPropagate, constraint.z)
    end

    # update useful variables
    setValue!(constraint.low, low)
    setValue!(constraint.up, up)

    # deactivate the constraint if necessary
    if isbound(constraint.z)
        zv = assignedValue(constraint.z)
        if all(zv == constraint.matrix[vx, vy] for vx in constraint.x.domain for vy in constraint.y.domain)
            setValue!(constraint.active, false)
        end
    end

    # check feasibility
    return !isempty(constraint.x.domain) && !isempty(constraint.y.domain) && !isempty(constraint.z.domain)
end

variablesArray(constraint::Element2D) = [constraint.x, constraint.y, constraint.z]

function Base.show(io::IO, ::MIME"text/plain", con::Element2D)
    println(io, "Element2D constraint: maxtrix[$(con.x.id), $(con.y.id)] == $(con.z.id)", ", active = ", con.active)
    println(io, "   matrix = ", con.matrix)
    println(io, "   ", con.x)
    println(io, "   ", con.y)
    print(io, "   ", con.z)
end

function Base.show(io::IO, con::Element2D)
    print(io, typeof(con), ": maxtrix[$(con.x.id), $(con.y.id)] == $(con.z.id)")
end

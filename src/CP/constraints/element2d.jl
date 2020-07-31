"""
    Element2D(matrix::Array{Int, 2}, x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)

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

function update_support_and_prune!(constraint, xyz, lost_position::Int)
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
"""
function propagate!(constraint::Element2D, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    low = constraint.low.value
    up = constraint.up.value
    z_min = minimum(constraint.z.domain)
    z_max = maximum(constraint.z.domain)
    xyz = constraint.xyz
    n, m = size(constraint.matrix)

    prunedX_b = removeBelow!(constraint.x.domain, 1)
    prunedX_a = removeAbove!(constraint.x.domain, n)
    prunedX = vcat(prunedX_b, prunedX_a)
    prunedY_b = removeBelow!(constraint.y.domain, 1)
    prunedY_a = removeAbove!(constraint.y.domain, m)
    prunedY = vcat(prunedY_b, prunedY_a)
    if !isempty(prunedX)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
    end
    if !isempty(prunedY)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
    end

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
        @assert low <= up
    end
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
        @assert low <= up
    end
    prunedZ_below = removeBelow!(constraint.z.domain, xyz[low][3])
    prunedZ_above = removeAbove!(constraint.z.domain, xyz[up][3])
    prunedZ = vcat(prunedZ_below, prunedZ_above)
    if !isempty(prunedZ)
        addToPrunedDomains!(prunedDomains, constraint.z, prunedZ)
        triggerDomainChange!(toPropagate, constraint.z)
    end
    setValue!(constraint.low, low)
    setValue!(constraint.up, up)
    
    if isbound(constraint.z)
        setValue!(constraint.active, false)
    end
    return !isempty(constraint.x.domain) && !isempty(constraint.y.domain) && !isempty(constraint.z.domain)
end

variablesArray(constraint::Element2D) = [constraint.x, constraint.y, constraint.z]
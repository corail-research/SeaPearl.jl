include("compacttableutils.jl")
"""
    ShortTableConstraint

Efficient implentation of the constraint enforcing: ∃ j ∈ ⟦1,m⟧, such that ∀ i ∈ ⟦1,n⟧ xᵢ=table[i,j].

The datastructure and the functions using it are inspired by:
Demeulenaere J. et al. (2016) Compact-Table: Efficiently Filtering Table Constraints with Reversible Sparse Bit-Sets.
In: Rueher M. (eds) Principles and Practice of Constraint Programming. CP 2016. Lecture Notes in Computer Science, vol 9892. Springer, Cham.
https://doi.org/10.1007/978-3-319-44953-1_14


    ShortTableConstraint(scope, active, table, currentTable, modifiedVariables, unfixedVariables, supports, residues)

ShortTableConstraint default constructor.

# Arguments
- `scope::Vector{<:AbstractIntVar}`: the ordered variables present in the table.
- `table::Matrix{Any}`: the original table describing the constraint (impossible assignment are filtered).
- `currentTable::RSparseBitSet{UInt64}`: the reversible representation of the table.
- `modifiedVariables::Vector{Int}`: vector with the indexes of the variables modified since the last propagation.
- `unfixedVariables::Vector{Int}`: vector with the indexes of the variables which are not binding.
- `supports::Dict{Pair{Int,Int},BitVector}`: dictionnary which, for each pair (variable => value), gives the support of this pair.
- `residues::Dict{Pair{Int,Int},Int}`: dictionnary which, for each pair (variable => value), gives the residue of this pair.


    ShortTableConstraint(variables, table, supports, trailer)

Create a CompactTable constraint from the `variables`, with values given in `table` and supports given in `supports`.

This constructor gives full control on both `table` and `supports`. The attributes are not duplicated and remains
linked to the variables given to the constructor. It should be used only to avoid duplication of `table` when using
the same table constraint many times with different variables. *WARNING*: all variables must have the same domain;
`table` and `supports` must be cleaned.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: vector of variables of size (n, ).
- `table::Matrix{Any}`: matrix of the constraint of size (n, m).
- `supports::Dict{Pair{Int,Int},BitVector}`: for each assignment, a list of the tuples supporting this assignment or supporting all value of the variable (aka * fields).
- `supportsStar::Dict{Pair{Int,Int},BitVector}`: for each assignment, a list of the tuples supporting this assignment, * field not taken in account as they still stay valid when a value is removed.
- `trailer::Trailer`: the trailer of the model.
"""
struct ShortTableConstraint <: Constraint
    scope::Vector{<:AbstractIntVar}
    active::StateObject{Bool}
    initialized::StateObject{Bool}
    table::Matrix{Any}
    currentTable::RSparseBitSet{UInt64}
    modifiedVariables::Set{Int}
    unfixedVariables::Set{Int}
    supports::Dict{Pair{Int,Int},BitVector}
    supportsStar::Dict{Pair{Int,Int},BitVector}
    residues::Dict{Pair{Int,Int},Int}

    ShortTableConstraint(scope, active, initialized, table, currentTable, modifiedVariables, unfixedVariables, supports, supportsStar, residues) = new(scope, active, initialized, table, currentTable, modifiedVariables, unfixedVariables, supports, supportsStar, residues)

    function ShortTableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Any}, supports::Dict{Pair{Int,Int},BitVector}, supportsStar::Dict{Pair{Int,Int},BitVector}, trailer)
        @assert length(variables) == size(table, 1)

        nVariables, nTuples = size(table)

        constraint = new(
            variables,
            StateObject{Bool}(true, trailer),
            StateObject{Bool}(false, trailer),
            table,
            RSparseBitSet{UInt64}(nTuples, trailer),
            Set{Int}(),
            Set(collect(1:nVariables)),
            supports,
            supportsStar, 
            buildResidues(supports)
        )

        for variable in variables
            addOnDomainChange!(variable, constraint)
        end

        return constraint
    end

end

"""
    ShortTableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Any}, trailer::SeaPearl.Trailer)

Create a CompactTable constraint from the `variables`, with values given in `table`.

This is the recommended constructor, as it safely builds the constraint and isolates it. If you choose any of the 2 other constructor,
beware how you create your attributes, and be sure not to modify them at any time.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: vector of variables of size (n, ).
- `table::Matrix{Any}`: matrix of the constraint of size (n, m).
- `trailer::Trailer`: the trailer of the model.
"""
function ShortTableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Any}, trailer)
    @assert length(variables) == size(table, 1)
    cleanedTable = cleanShortTable(variables, table)

    active = StateObject{Bool}(true, trailer)
    initialized = StateObject{Bool}(false, trailer)
    nVariables, nTuples = size(cleanedTable)
    currentTable = RSparseBitSet{UInt64}(nTuples, trailer)
    modifiedVariables = Set{Int}()
    unfixedVariables = Set(collect(1:nVariables))

    supports = buildShortSupport(variables, cleanedTable)
    supportsStar = buildShortSupportStar(variables, cleanedTable)
    cleanShortSupports!(supports)
    cleanShortSupports!(supportsStar)

    residues = buildResidues(supports)
    constraint = ShortTableConstraint(
        variables,
        active,
        initialized,
        cleanedTable,
        currentTable,
        modifiedVariables,
        unfixedVariables,
        supports,
        supportsStar,
        residues
    )

    for variable in variables
        addOnDomainChange!(variable, constraint)
    end

    return constraint
end

"""
    cleanShortTable(variables, table)::Matrix{Any}

Return a table without the columns corresponding to impossible assignments.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
- `table::Matrix{Any}`: the table of the constraint.
"""
function cleanShortTable(variables::Vector{<:AbstractIntVar}, table::Matrix{Any})::Matrix{Any}
    tuplesToDrop = Set{Int}()
    for (idx, col) in enumerate(eachcol(table))
        isValid = all([value in variable.domain || value == "*" for (variable, value) in zip(variables, col)])
        if !isValid
            push!(tuplesToDrop, idx)
        end
    end
    return table[:, setdiff(1:size(table, 2), tuplesToDrop)]
end

"""
    buildShortSupport(variables, table)::Dict{Pair{Int,Int},BitVector}

Return the support dictionnary, giving for each pair wich columns of the table uses it. Give also columns with "*"

# Arguments
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
- `table::Matrix{Any}`: the table of the constraint.
"""
function buildShortSupport(variables::Vector{<:AbstractIntVar}, table::Matrix{Any})::Dict{Pair{Int,Int},BitVector}
    nVariables, nTuples = size(table)

    support = Dict{Pair{Int,Int},BitVector}()
    for (idx, var) in enumerate(variables), a in var.domain
        support[idx => a] = BitVector(fill(false, nTuples))
    end

    for (idx, col) in enumerate(eachcol(table)), (variable, value) in enumerate(col)
        # Value is an Integer
        if typeof(value) == Int
            support[variable => value][idx] = true

        #Value is "*", the tuple should be added to every value
        else
            for v in variables[variable].domain
                support[variable => v][idx] = true
            end
        end
    end

    return support
end

"""
    buildShortSupportStar(variables, table)::Dict{Pair{Int,Int},BitVector}

Return the support dictionnary, giving for each pair wich columns of the table uses it. Columns with "*" are not considered

# Arguments
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
- `table::Matrix{Any}`: the table of the constraint.
"""
function buildShortSupportStar(variables::Vector{<:AbstractIntVar}, table::Matrix{Any})::Dict{Pair{Int,Int},BitVector}
    nVariables, nTuples = size(table)

    support = Dict{Pair{Int,Int},BitVector}()
    for (idx, var) in enumerate(variables), a in var.domain
        support[idx => a] = BitVector(fill(false, nTuples))
    end

    for (idx, col) in enumerate(eachcol(table)), (variable, value) in enumerate(col)
        # Value is an Integer
        if typeof(value) == Int
            support[variable => value][idx] = true
        end
    end

    return support
end

"""
    cleanSupports!(supports, variables)

Remove the pair (variable => value) from `supports` and from the variables domain, when they aren't present in the table.

# Arguments
- `supports::Dict{Pair{Int,Int},BitVector}`: the previously generated supports of the constraint.
"""
function cleanShortSupports!(supports::Dict{Pair{Int,Int},BitVector})::Nothing
    for ((variable, value), support) in supports
        if !any(support)
            delete!(supports, variable => value)
        end
    end
    return
end

"""
    initialPruning!(constraint, prunedValues)

Store all the assignments without support in `prunedValues` for them to be pruned.
"""
function initialPruning!(constraint::ShortTableConstraint, prunedValues::Vector{Vector{Int}})
    for (idx, variable) in enumerate(constraint.scope), value in variable.domain
        if !((idx => value) in keys(constraint.supports))
            push!(prunedValues[idx], value)
        end
    end
    return
end

"""
    updateShortTable!(constraint, prunedValues)

Remove the outdated columns from the reversible table of the constraint.

This function is directly inspired by Demeulenaere J. et al. paper.
"""
function updateShortTable!(constraint::ShortTableConstraint, prunedValues::Vector{Vector{Int}})::Bool
    for variable in constraint.modifiedVariables
        clearMask!(constraint.currentTable)
        if length(prunedValues[variable]) < length(constraint.scope[variable].domain)
            for value in prunedValues[variable]
                support = bitVectorToUInt64Vector(constraint.supportsStar[variable => value])
                addToMask!(constraint.currentTable, support)
            end
            reverseMask!(constraint.currentTable)
        else
            for value in constraint.scope[variable].domain
                if haskey(constraint.supports, variable => value)
                    support = bitVectorToUInt64Vector(constraint.supports[variable => value])
                    addToMask!(constraint.currentTable, support)
                end
            end
        end
        intersectWithMask!(constraint.currentTable)
        if isempty(constraint.currentTable)
            return false
        end
    end
    return true
end

"""
    pruneDomains!(constraint, prunedValues)

Remove the impossible values from the variables domain update prunedValues.

This function is directly inspired by Demeulenaere J. et al. paper.
"""
function pruneDomains!(constraint::ShortTableConstraint)::Vector{Vector{Int}}
    prunedValues = Vector{Vector{Int}}(undef, length(constraint.scope))
    for i = 1:length(constraint.scope)
        prunedValues[i] = Int[]
    end

    for variable in constraint.unfixedVariables, value in constraint.scope[variable].domain
        index = constraint.residues[variable => value]
        support = bitVectorToUInt64Vector(constraint.supports[variable => value])
        if constraint.currentTable.words[index].value & support[index] == UInt64(0)
            index = intersectIndex(constraint.currentTable, support)
            if index != -1
                constraint.residues[variable => value] = index
            else
                push!(prunedValues[variable], value)
            end
        end
    end
    return prunedValues
end

"""
    propagate!(constraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`ShortTableConstraint` propagation function. Implement the full procedure of the paper.
"""
function propagate!(constraint::ShortTableConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end
    
    initialPrunedValues = nothing
    if !constraint.initialized.value
        initialPrunedValues = Vector{Vector{Int}}(undef, length(constraint.scope))
        for i = 1:length(constraint.scope)
            initialPrunedValues[i] = Int[]
        end
        initialPruning!(constraint, initialPrunedValues)
        setValue!(constraint.initialized, true)
        for (variable, toRemove) in enumerate(initialPrunedValues), v in toRemove
            remove!(constraint.scope[variable].domain, v)
        end
    end

    # Store all the changes concerning the variables in `constraint.scope`
    prunedValues = Vector{Vector{Int}}(undef, length(constraint.scope))
    empty!(constraint.modifiedVariables)
    for (idx, variable) in enumerate(constraint.scope)
        if haskey(prunedDomains, variable.id)
            push!(constraint.modifiedVariables, idx)
            prunedValues[idx] = copy(prunedDomains[variable.id])
        end
    end
            
    # Sometime an assignment has already been pruned before the initialization eventhough  
    # it doesn't have a support .In that case it shouldn't be used to update the table.
    for variable in constraint.modifiedVariables
        filter!(prunedValues[variable]) do value
            haskey(constraint.supports, variable => value)
        end
    end

    # Update unfixed variables
    empty!(constraint.unfixedVariables)
    union!(constraint.unfixedVariables, findall(var -> length(var.domain) > 1, constraint.scope))

    # Remove impossible supports from the table
    if !updateShortTable!(constraint, prunedValues)
        return false
    end

    # Restrict domains to the new supports
    newPrunedValues = pruneDomains!(constraint)
    if !isnothing(initialPrunedValues)
        for i = 1:length(constraint.scope)
            append!(newPrunedValues[i], initialPrunedValues[i])
        end
    end
    for (prunedVar, var) in zip(newPrunedValues, constraint.scope)
        if !isempty(prunedVar)
            for val in prunedVar
                remove!(var.domain, val)
            end
            triggerDomainChange!(toPropagate, var)
            addToPrunedDomains!(prunedDomains, var, prunedVar)
        end
    end

    if constraint in toPropagate
        pop!(toPropagate, constraint)
    end

    return true
end

function Base.show(io::IO, ::MIME"text/plain", con::ShortTableConstraint)
    table = split(repr("text/plain", con.table), '\n')[2:end]
    maxlen = Base.maximum(x -> length(x.id), con.scope)

    println(io, string(typeof(con)), ": active = ", con.active)
    for i = 1:length(con.scope)
        println(io, "   ", rpad(con.scope[i].id, maxlen),"  in  ", table[i])
    end
    print(io, "\n   With domains:")
    for var in con.scope
        print(io, "\n      ", var)
    end
end

function Base.show(io::IO, con::ShortTableConstraint)
    print(io, string(typeof(con)), ": (", join([x.id for x in con.scope], ", "), ") in ", con.table, ", active = ", con.active)
end

variablesArray(constraint::ShortTableConstraint) = constraint.scope

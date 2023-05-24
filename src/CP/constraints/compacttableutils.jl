"""
    buildResidues(variables, supports)::Dict{Pair{Int,Int},Int}

Return the residues from the variables and the cleaned supports.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
- `supports::Dict{Pair{Int,Int},BitVector}`: the previously generated supports of the constraint.
"""
function buildResidues(supports::Dict{Pair{Int,Int},BitVector})::Dict{Pair{Int,Int},Int}
    residues = Dict{Pair{Int,Int},Int}()
    n = 64
    for (key, support) in supports
        residues[key] = Int(ceil(findfirst(support)/n))
    end
    return residues
end
"""
    function Element1D(matrix::Array{Int, 1}, i::AbstractIntVar, x::AbstractIntVar, trailer::Trailer)

Create a constraint stating that `matrix[i] == x`
"""

function Element1D(matrix::Array{Int, 1}, i::AbstractIntVar, x::AbstractIntVar, trailer::Trailer)
    return Element2D(matrix[:, :], i, IntVar(1, 1, "one", trailer), x, trailer)
end
abstract type SearchStrategy end

struct DFSearch <: SearchStrategy end
struct ILDSearch <: SearchStrategy end

abstract type RBSearch <: SearchStrategy end
struct staticRBSearch <: RBSearch
    L::Int64
    n::Int64
end
struct geometricRBSearch <: RBSearch
    L::Int64
    n::Int64
    α::Float32
end
struct lubyRBSearch <: RBSearch
    L::Int64
    n::Int64

end
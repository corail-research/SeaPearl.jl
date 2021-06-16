abstract type SearchStrategy end

struct DFSearch <: SearchStrategy end
struct ILDSearch <: SearchStrategy end

abstract type RBSSearch <: SearchStrategy end

struct staticRBSSearch <: RBSSearch
    L::Int64
    n::Int64
end
struct geometricRBSSearch <: RBSSearch
    L::Int64
    n::Int64
    α::Float32
end
struct lubiRBSSearch <: RBSSearch
    L::Int64
    n::Int64

end
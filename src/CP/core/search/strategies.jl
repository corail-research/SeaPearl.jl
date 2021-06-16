abstract type SearchStrategy end

struct DFSearch <: SearchStrategy end
struct ILDSearch <: SearchStrategy end

abstract type RBSSearch <: SearchStrategy end

struct staticRBSSearcn <: RBSSearch
    L::Int64
end
struct geometricRBSSearcn <: RBSSearch
    L::Int64
    α::Float32
end
struct lubiRBSSearcn <: RBSSearch
    L::Int64

end
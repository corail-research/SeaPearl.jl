struct DisjointSet
    size::Int
    parent::Array{Int}
    DisjointSet(size) = new(size, fill(-1, size))
end

function union!(disjointSet::DisjointSet, representative1::Int, representative2::Int)
    #assert disjointSet.parent[representative1] < 0 && disjointSet.parent[representative1] < 0
    if (disjointSet.parent[representative1] < disjointSet.parent[representative2])
        disjointSet.parent[representative2] = representative1
    elseif (disjointSet.parent[representative2] < disjointSet.parent[representative1])
        disjointSet.parent[representative1] = representative2
    else
        disjointSet.parent[representative1] = representative2
        disjointSet.parent[representative2] = disjointSet.parent[representative2] - 1
    end
end


function findRepresentative!(disjointSet::DisjointSet, element)
    root = element
    while (disjointSet.parent[root] >= 0)
        root = disjointSet.parent[root]
    end
    while (element != root)
        temporary_element = disjointSet.parent[element]
        disjointSet.parent[element] = root
        element = temporary_element
    end
    return root
end
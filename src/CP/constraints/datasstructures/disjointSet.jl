struct DisjointSet
    size::Int
    parent::Array{Int}
    min::Array{Int}
    max::Array{Int}
    DisjointSet(size) = new(size, fill(-1, size), collect(1:size), collect(1:size))
end

function union!(disjointSet::DisjointSet, representative1::Int, representative2::Int)
    #assert disjointSet.parent[representative1] < 0 && disjointSet.parent[representative1] < 0
    if (disjointSet.parent[representative1] < disjointSet.parent[representative2])
        disjointSet.parent[representative2] = representative1
        disjointSet.max[representative1] = max(disjointSet.max[representative1], disjointSet.max[representative2]);
        disjointSet.min[representative1] = min(disjointSet.min[representative1], disjointSet.min[representative2]);
    elseif (disjointSet.parent[representative2] < disjointSet.parent[representative1])
        disjointSet.parent[representative1] = representative2
        disjointSet.max[representative2] = max(disjointSet.max[representative1], disjointSet.max[representative2]);
        disjointSet.min[representative2] = min(disjointSet.min[representative1], disjointSet.min[representative2]);
    else
        disjointSet.parent[representative1] = representative2
        disjointSet.parent[representative2] = disjointSet.parent[representative2] - 1
        disjointSet.max[representative2] = max(disjointSet.max[representative1], disjointSet.max[representative2]);
        disjointSet.min[representative2] = min(disjointSet.min[representative1], disjointSet.min[representative2]);
    end
    
end


function findRepresentative!(disjointSet::DisjointSet, element::Int)
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

function greatest!(disjointSet::DisjointSet, element::Int) 
    representative = findRepresentative!(disjointSet, element)
    return disjointSet.max[representative]
end

function smallest!(disjointSet::DisjointSet, element::Int) 
    representative = findRepresentative!(disjointSet, element)
    return disjointSet.min[representative]
end


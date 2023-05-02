using XML

function find_element(x::Node, tag::AbstractString)
    for node in children(x)
        if node.tag == tag
            return node
        end
    end
    return nothing
end

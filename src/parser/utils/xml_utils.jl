using XML

function find_element(x::Node, tag::AbstractString)
    for node in children(x)
        if node.tag == tag
            return node
        end
    end
    return nothing
end

function get_node_string(x::Node)
    return children(x)[1].value
end
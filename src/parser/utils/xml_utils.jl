using XML

function find_element(x::Node, tag::AbstractString)
    for node in XML.children(x)
        if node.tag == tag
            return node
        end
    end
    return nothing
end

function get_node_string(x::Node)
    return XML.children(x)[1].value
end

function is_digit(str::AbstractString)
    for i in length(str)
        c = str[i]
        if !isdigit(c)
            if i == 0 && c == '-'
                continue
            else
                return false
            end
        end
    end
    return true
end
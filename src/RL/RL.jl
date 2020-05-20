

function selectValue(x::IntVar)
    return maximum(x.domain)
end

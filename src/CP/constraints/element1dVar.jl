"""
    Element1DVar(array::Array{Int, 1}, y::AbstractIntVar, z::AbstractIntVar, SeaPearl.trailer)

Element1DVar constraint, states that `matrix[y] == z`
"""

struct Element1DVar <: Constraint
    array::Vector{AbstractIntVar}
    y::AbstractIntVar
    z::AbstractIntVar
    yValues::Array{Int, 1}
    zValues::Array{Int, 1}

    # supportArr(i) is a value that is in both dom(array(i)) and dom(z)
    # if not possible to find a supportArr(i) satisfying this condition, 
    # then i can be removed from x
    supportArr::Array{StateObject{Int}, 1}
    # supportZ(v) is an index i such that 1) i is in dom(y) and 2) v in dom(Arr(i))
    # if not possible to find a supportZ(v) then v can be removed from z
    supportZ::Array{StateObject{Int}, 1}
    zMin::StateObject{Int}
    zMax::StateObject{Int}
    active::StateObject{Bool}

    function Element1DVar(array::Array{<:AbstractIntVar, 1}, y::AbstractIntVar, z::AbstractIntVar, trailer)
        yValues = [0 for i in 1:length(y.domain)]
        zValues = [0 for i in 1:length(z.domain)]
        sizey = fillArray!(yValues, y)
        sizez = fillArray!(zValues, z)
        supportArr = [StateObject{Int}(minimum(z.domain)-1, trailer) for i in 1:length(y.domain)]
        supportZ = [StateObject{Int}(minimum(y.domain)-1, trailer) for i in 1:length(z.domain)]
        zMin = SeaPearl.StateObject{Int}(minimum(z.domain), trailer)
        zMax = SeaPearl.StateObject{Int}(maximum(z.domain), trailer)
        
        constraint = new(array, 
                         y, 
                         z, 
                         yValues, 
                         zValues, 
                         supportArr, 
                         supportZ, 
                         zMin,
                         zMax, 
                         StateObject{Bool}(true, trailer))
        
        for xi in [y, z]
            addOnDomainChange!(xi, constraint)
        end
        for xi in array
            addOnDomainChange!(xi, constraint)
        end
        return constraint
    end
end

"""
    propagate!(constraint::Element1DVar, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`Element1DVar` propagation function.
"""
function propagate!(constraint::Element1DVar, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    
    setValue!(constraint.zMin, minimum(constraint.z.domain))
    update_support_and_filter!(constraint, toPropagate, prunedDomains)

    if isbound(constraint.y)
        y_val = assignedValue(constraint.y)
        indexArrVar = findfirst(isequal(y_val), constraint.yValues)
        prunedArray = pruneEqual!(constraint.array[indexArrVar], constraint.z)
        
        if !isempty(prunedArray)
            addToPrunedDomains!(prunedDomains, constraint.array[indexArrVar], prunedArray)
            triggerDomainChange!(toPropagate, constraint.array[indexArrVar])
        end
        # deactivate the constraint
        setValue!(constraint.active, false)
    end

    # check feasibility
    return !isempty(constraint.y.domain) && !isempty(constraint.z.domain) && all(!isempty(constraint.array[yi-minimum(constraint.y.domain)+1].domain for yi in constraint.y.domain))
end


function fillArray!(dest::Array{Int, 1}, var::AbstractIntVar)
    # 
    # Copies the values of the domain into an array.
    # 
    # @param dest an array large enough {@code dest.length >= size()}
    # @return the size of the domain and {@code dest[0,...,size-1]} contains
    #        the values in the domain in an arbitrary order
    # 
    i = 0
    for v in var.domain
        i += 1
        dest[i] = v
    end
    return i
end

"""
    update_support_and_filter!(constraint::Element1DVar, toPropagate::Set{Constraint}, prunedDomains::CPModification)
"""
function update_support_and_filter!(constraint::Element1DVar, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    mz = constraint.z.domain.size.value
    my = constraint.y.domain.size.value
    indicesYValuesKept = []
    i = 1
    while i <= my
        if !updateSupportArr!(constraint, i, mz)
            pruneY = remove!(constraint.y.domain, constraint.yValues[i])
            if !isempty(pruneY)
                addToPrunedDomains!(prunedDomains, constraint.y, pruneY)
                triggerDomainChange!(toPropagate, constraint.y)
            end
        else
            push!(indicesYValuesKept, i)
        end
        i += 1
    end
    mz = constraint.z.domain.size.value
    my = constraint.y.domain.size.value
    i = 1
    while i <= mz
        if !updateSupportZ!(constraint, constraint.zValues[i], i, my, indicesYValuesKept)
            pruneZ = remove!(constraint.z.domain, constraint.zValues[i])
            if !isempty(pruneZ)
                addToPrunedDomains!(prunedDomains, constraint.z, pruneZ)
                triggerDomainChange!(toPropagate, constraint.z)
            end
            setValue!(constraint.zMin, minimum(constraint.z.domain))
            setValue!(constraint.zMax, maximum(constraint.z.domain))
        end
        i += 1
    end
end

"""
    updateSupportArr!(constraint::Element1DVar, indexYValue::Int, sizeZ::Int)::Bool
"""
function updateSupportArr!(constraint::Element1DVar, indexYValue::Int, sizeZ::Int)::Bool
    
    # Return true if the support of the array[indexYValue] is still valid or if we find a new valid support, otherwise return false
    if in(constraint.supportArr[indexYValue], constraint.array[indexYValue].domain) && in(constraint.supportArr[indexYValue], constraint.z.domain)
        return true
    else
        k = 1
        while k <= sizeZ
            if in(constraint.zValues[k], constraint.array[indexYValue].domain)
                setValue!(constraint.supportArr[indexYValue], constraint.zValues[k])
                return true
            end
            k += 1
        end
        return false
    end
end

"""
    updateSupportZ!(constraint::Element1DVar, valueZ::Int, indexValueZ::Int, sizeY::Int, indicesYValuesKept)::Bool
"""
function updateSupportZ!(constraint::Element1DVar, valueZ::Int, indexValueZ::Int, sizeY::Int, indicesYValuesKept)::Bool
    if in(constraint.supportZ[indexValueZ], constraint.y.domain) && in(valueZ, constraint.array[constraint.supportZ[indexValueZ]].domain)
        return true
    else
        indexArrVar = nothing
        i = 1
        for i in indicesYValuesKept
            if in(valueZ, constraint.array[i].domain)
                setValue!(constraint.supportZ[indexValueZ], constraint.yValues[i])
                return true
            end
            i += 1
        end
        return false
    end
end

function variablesArray(constraint::Element1DVar)
    y_z_list = [constraint.y, constraint.z]
    arr_list = [Ti for Ti in constraint.array]
    return vcat(y_z_list, arr_list)
end

function Base.show(io::IO, ::MIME"text/plain", con::Element1DVar)
    list_id_array = [var.id for var in con.array]
    println(io, "Element1DVar constraint: Array[$(con.y.id)] == $(con.z.id) with Array = $(list_id_array)", ", active = ", con.active)
    println(io, "   ", con.y)
    println(io, "   ", con.z)
    print(io, "   ", con.array)
end

function Base.show(io::IO, con::Element1DVar)
    list_id_array = [var.id for var in con.array]
    list_id_array_str = "[$(join(list_id_array, ", "))]"
    print(io, typeof(con), ": Array[$(con.y.id)] == $(con.z.id) with Array = $(list_id_array_str)")
end

"""
    Addition(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar)

Summing constraint, states that `z == x + y`
"""

function Addition(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)
    opposite_z = IntVarViewOpposite(z, "-"*z.id)
    vars = [opposite_z, x, y]

    return SumToZero(vars, trailer)
end


"""
    Subtraction(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar)

Summing constraint, states that `z == x - y`
"""

function Subtraction(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)
    opposite_y = IntVarViewOpposite(y, "-"*y.id)
    opposite_z = IntVarViewOpposite(z, "-"*z.id)
    vars = [opposite_z, x, opposite_y]

    return SumToZero(vars, trailer)
end

"""
    Multiplication(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar)

Non-linear constraint, states that `z == x * y`
"""

struct Multiplication <: Constraint
    x       ::SeaPearl.AbstractIntVar
    y       ::SeaPearl.AbstractIntVar
    z       ::SeaPearl.AbstractIntVar
    active  ::StateObject{Bool}
    function Multiplication(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)
        constraint = new(x, y, z, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        addOnDomainChange!(z, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::Multiplication, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`Multiplication` propagation function.
"""
function propagate!(constraint::Multiplication, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end
    
    minZ, maxZ =  mulBounds!(minimum(constraint.x.domain), maximum(constraint.x.domain), minimum(constraint.y.domain), maximum(constraint.y.domain))
    prunedZ = vcat(removeBelow!(constraint.z.domain, minZ), removeAbove!(constraint.z.domain, maxZ))

    if !isempty(prunedZ)
        triggerDomainChange!(toPropagate, constraint.z)
        addToPrunedDomains!(prunedDomains, constraint.z, prunedZ)
    end

    Z0 = 0 in constraint.z.domain

    prunedX = Int[]
    prunedY = Int[]

    if !Z0
        prunedY = vcat(prunedY, remove!(constraint.y.domain, 0))
        prunedX = vcat(prunedX, remove!(constraint.x.domain, 0))
        X0 = false
        Y0 = false
    else
        X0 = 0 in constraint.x.domain
        Y0 = 0 in constraint.y.domain
    end

    # if isempty(constraint.x.domain) || isempty(constraint.y.domain)
    #     return false
    
    # If 0 in y.domain, domain of x cannot be pruned 
    if !Y0
        minX, maxX = divBounds!(minimum(constraint.z.domain), maximum(constraint.z.domain), minimum(constraint.y.domain), maximum(constraint.y.domain))
        prunedX1 = vcat(removeBelow!(constraint.x.domain, minX), removeAbove!(constraint.x.domain, maxX))
        prunedX = vcat(prunedX, prunedX1)
    end

    # If 0 in x.domain, domain of y cannot be pruned 
    if !X0
        minY, maxY = divBounds!(minimum(constraint.z.domain), maximum(constraint.z.domain), minimum(constraint.x.domain), maximum(constraint.x.domain))
        prunedY1 = vcat(removeBelow!(constraint.y.domain, minY), removeAbove!(constraint.y.domain, maxY))
        prunedY = vcat(prunedY, prunedY1)
    end
        
    if !isempty(prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
    end
            
    if !isempty(prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
    end

    if isbound(constraint.x) || isbound(constraint.y) || isbound(constraint.z)
        setValue!(constraint.active, false)
    end
    if isempty(constraint.x.domain) || isempty(constraint.y.domain) || isempty(constraint.z.domain)
        return false
    end
    return true
end

variablesArray(constraint::Multiplication) = [constraint.x, constraint.y, constraint.z]

function Base.show(io::IO, ::MIME"text/plain", con::Multiplication)
    println(io, typeof(con), ": ", con.x.id, " * ", con.y.id, " == " , con.z.id, ", active = ", con.active)
    println(io, "   ", con.x)
    print(io, "   ", con.y)
end

function Base.show(io::IO, con::Multiplication)
    print(io, typeof(con), ": ", con.x.id, " * ", con.y.id, " == " , con.z.id)
end


"""
mulBounds!(a::Int, b::Int, c::Int, d::Int)

Finds result interval for multiplication of {a..b} * {c..d}
"""
function mulBounds!(a::Int, b::Int, c::Int, d::Int)
    
    ac = a * c
    ad = a * d
    bc = b * c
    bd = b * d

    min, idx = Base.findmin([ac, ad, bc, bd])
    max, idx = Base.findmax([ac, ad, bc, bd])

    return min, max
end


"""
divBounds!(a::Int, b::Int, c::Int, d::Int)pruneDivision!(prunedVar::AbstractIntVar, numeratorVar::AbstractIntVar, denominatorVar::AbstractIntVar)

Finds result interval for division of {a..b} ÷ {c..d}
"""
function divBounds!(a::Int, b::Int, c::Int, d::Int)
    if (a > b || c > d)
        error("Bad bound definition for divBounds!")
    end

    # c = 0, d = 0
    if (c == 0 && d == 0)
        error("Cannot divide by zero")
    
    # c = 0, d > 0
    elseif (c == 0)
        divBounds!(a,b,1,d)

    # c < 0, d = 0
    elseif (d == 0)
        divBounds!(a,b,c,-1)
    
    # c > 0, d > 0 or c < 0, d < 0
    elseif (c > 0 || d < 0)
        ac = a / c
        ad = a / d
        bc = b / c
        bd = b / d
        low, idx = Base.findmin([ac, ad, bc, bd])
        high, idx = Base.findmax([ac, ad, bc, bd])

        min = Int(ceil(low))
        max = Int(floor(high))

        # If low and high are between the same consecutive integers
        if (min > max)
            min = max 
            max = min 
        end
        return min, max
    
    # c < 0, d > 0
    else
        min_neg, max_neg = divBounds!(a, b, c, -1)
        min_pos, max_pos = divBounds!(a, b, 1, d)

        min, idx =  Base.findmin([min_neg, max_neg, min_pos, max_pos])
        max, idx =  Base.findmax([min_neg, max_neg, min_pos, max_pos])

        if (min > max)
            error("Fail to find division bounds")
        end

        return min, max
    end
end

"""
reminderBounds!(a::Int, b::Int, c::Int, d::Int)pruneDivision!(prunedVar::AbstractIntVar, numeratorVar::AbstractIntVar, denominatorVar::AbstractIntVar)

Finds result interval for reminder of {a..b} mod {c..d}
"""
function reminderBounds!(a::Int, b::Int, c::Int, d::Int)

    maxAbsCD, idx = Base.findmax([c, -c, d, -d])

    if a >= 0
        reminderMin = 0
        reminderMax = maxAbsCD - 1
    elseif b < 0
        reminderMin = -maxAbsCD + 1
        reminderMax = 0
    else 
        reminderMin = -maxAbsCD + 1
        reminderMax = maxAbsCD - 1
    end

    return reminderMin, reminderMax
end


"""
Division(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar)

Euclidian division constraint, states that `z == x ÷ y`
"""

struct Division <: Constraint
    x       ::SeaPearl.AbstractIntVar
    y       ::SeaPearl.AbstractIntVar
    z       ::SeaPearl.AbstractIntVar
    active  ::StateObject{Bool}
    function Division(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)
        constraint = new(x, y, z, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        addOnDomainChange!(z, constraint)
        return constraint
    end
end

function propagate!(constraint::Division, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end
    
    xDomain = constraint.x.domain
    yDomain = constraint.y.domain
    zDomain = constraint.z.domain

    # Impossible division by 0
    prunedY0 = remove!(yDomain, 0)
    
    # Prune z domain
    minZ, maxZ = divBounds!(minimum(xDomain), maximum(xDomain), minimum(yDomain), maximum(yDomain))
    prunedZ = vcat(removeBelow!(zDomain, minZ), removeAbove!(zDomain, maxZ))

    X0 = 0 in xDomain

    prunedZ0 = Int[]

    # If 0 is not in x domain, it cannot be within z domain
    if !X0
        prunedZ0 = remove!(zDomain, 0)
        prunedZ = vcat(prunedZ0, prunedZ)
    end

    if !isempty(prunedZ)
        triggerDomainChange!(toPropagate, constraint.z)
        addToPrunedDomains!(prunedDomains, constraint.z, prunedZ)
    end

    Z0 = !isempty(prunedZ0)
    
    # Prune y domain 

    reminderMin, reminderMax = reminderBounds!(minimum(xDomain), maximum(xDomain), minimum(yDomain), maximum(yDomain))

    # If 0 in x.domain and z.domain, domain of x cannot be pruned 
    if !(Z0 & X0)
        minY, maxY = divBounds!(minimum(xDomain) - reminderMax, maximum(xDomain) -reminderMin, minimum(zDomain), maximum(zDomain))

        #If x and z have same sign, y is positive
        if (minimum(xDomain) >= 0 & minimum(zDomain) >= 0) || (minimum(xDomain) <= 0 & minimum(zDomain) <= 0)
            minY = 1

        #If x and z have opposite sign, y is negative
        elseif (minimum(xDomain) >= 0 & minimum(zDomain) <= 0) || (minimum(xDomain) <= 0 & minimum(zDomain)>= 0)
            maxY = -1
        end

        prunedY = vcat(removeBelow!(yDomain, minY), removeAbove!(yDomain, maxY))
        prunedY = vcat(prunedY0, prunedY)
    end
            
    if !isempty(prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
    end

    # Prune x domain

    minYZ, maxYZ = mulBounds!(minimum(yDomain), maximum(yDomain), minimum(zDomain), maximum(zDomain))

    # Test if we have more precise bounds for reminderMin and reminderMax
    reminderMin, reminderMax = reminderBounds!(minimum(xDomain), maximum(xDomain), minimum(yDomain), maximum(yDomain))

    rMin = minimum(xDomain) - maxYZ
    rMax = maximum(xDomain) - minYZ
    if reminderMin > rMin
        rMin = reminderMin
    end
    if reminderMax < rMax
        rMax = reminderMax
    end

    prunedX = vcat(removeBelow!(xDomain, minYZ + rMin), removeAbove!(xDomain, maxYZ + rMax))

    if !isempty(prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
    end


    if isbound(constraint.x) & isbound(constraint.y) & isbound(constraint.z)
        setValue!(constraint.active, false)
    end
    if isempty(constraint.x.domain) || isempty(constraint.y.domain) || isempty(constraint.z.domain)
        return false
    end
    return true
end

variablesArray(constraint::Division) = [constraint.x, constraint.y, constraint.z]

function Base.show(io::IO, ::MIME"text/plain", con::Division)
    println(io, typeof(con), ": ", con.x.id, " ÷ ", con.y.id, " == " , con.z.id, ", active = ", con.active)
    println(io, "   ", con.x)
    print(io, "   ", con.y)
end

function Base.show(io::IO, con::Division)
    print(io, typeof(con), ": ", con.x.id, " ÷ ", con.y.id, " == " , con.z.id)
end

"""
Modulo(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar)

Modulo constraint, states that `z == x % y`
"""

struct Modulo <: Constraint
    x       ::SeaPearl.AbstractIntVar
    y       ::SeaPearl.AbstractIntVar
    z       ::SeaPearl.AbstractIntVar
    active  ::StateObject{Bool}
    function Modulo(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)
        constraint = new(x, y, z, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        addOnDomainChange!(z, constraint)
        return constraint
    end
end

function propagate!(constraint::Modulo, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end
    
    xDomain = constraint.x.domain
    yDomain = constraint.y.domain
    zDomain = constraint.z.domain

    # Impossible division by 0
    prunedY0 = remove!(yDomain, 0)
    
    # Prune z domain
    minZ, maxZ = reminderBounds!(minimum(xDomain), maximum(xDomain), minimum(yDomain), maximum(yDomain))
    prunedZ = vcat(removeBelow!(zDomain, minZ), removeAbove!(zDomain, maxZ))

    if !isempty(prunedZ)
        triggerDomainChange!(toPropagate, constraint.z)
        addToPrunedDomains!(prunedDomains, constraint.z, prunedZ)
    end
    
    # Prune y domain 

    XYmin, XYmax = divBounds!(minimum(xDomain), maximum(xDomain), minimum(yDomain), maximum(yDomain))

    minY, maxY = divBounds!(minimum(xDomain) - maximum(zDomain), maximum(xDomain) - minimum(zDomain), XYmin, XYmax)

    prunedY = vcat(removeBelow!(yDomain, minY), removeAbove!(yDomain, maxY))
    prunedY = vcat(prunedY0, prunedY)
            
    if !isempty(prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
    end

    # Prune x domain
    
    minX, maxX = mulBounds!(XYmin, XYmax, minimum(yDomain), maximum(yDomain))

    prunedX = vcat(removeBelow!(xDomain, minX + minimum(zDomain)), removeAbove!(xDomain, maxX + maximum(zDomain)))

    if !isempty(prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
    end


    if isbound(constraint.x) & isbound(constraint.y) & isbound(constraint.z)
        setValue!(constraint.active, false)
    end
    if isempty(constraint.x.domain) || isempty(constraint.y.domain) || isempty(constraint.z.domain)
        return false
    end
    return true
end

variablesArray(constraint::Modulo) = [constraint.x, constraint.y, constraint.z]

function Base.show(io::IO, ::MIME"text/plain", con::Modulo)
    println(io, typeof(con), ": ", con.x.id, " mod ", con.y.id, " == " , con.z.id, ", active = ", con.active)
    println(io, "   ", con.x)
    print(io, "   ", con.y)
end

function Base.show(io::IO, con::Modulo)
    print(io, typeof(con), ": ", con.x.id, " mod ", con.y.id, " == " , con.z.id)
end
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
    
    minZ, maxZ =  mulBounds!(constraint.x.domain.min.value, constraint.x.domain.max.value, constraint.y.domain.min.value, constraint.y.domain.max.value)
    prunedZ = vcat(removeBelow!(constraint.z.domain, minZ), removeAbove!(constraint.z.domain, maxZ))

    if !isempty(prunedZ)
        triggerDomainChange!(toPropagate, constraint.z)
        addToPrunedDomains!(prunedDomains, constraint.z, prunedZ)
    end

    Z0 = 0 in constraint.z.domain

    prunedX0 = Int[]
    prunedY0 = Int[]

    if !Z0
        prunedY0 = remove!(constraint.y.domain, 0)
        prunedX0 = remove!(constraint.x.domain, 0)
    end

    X0 = !isempty(prunedX0)
    Y0 = !isempty(prunedY0)
    
    # If 0 in y.domain and z.domain, domain of x cannot be pruned 
    if !(Z0 & Y0)
        minX, maxX = divBounds!(constraint.z.domain.min.value, constraint.z.domain.max.value, constraint.y.domain.min.value, constraint.y.domain.max.value)
        prunedX = vcat(removeBelow!(constraint.x.domain, minX), removeAbove!(constraint.x.domain, maxX))
        prunedX = vcat(prunedX0, prunedX)
    end

    # If 0 in x.domain and z.domain, domain of y cannot be pruned 
    if !(Z0 & X0)
        minY, maxY = divBounds!(constraint.z.domain.min.value, constraint.z.domain.max.value, constraint.x.domain.min.value, constraint.x.domain.max.value)
        prunedY = vcat(removeBelow!(constraint.y.domain, minY), removeAbove!(constraint.y.domain, maxY))
        prunedY = vcat(prunedY0, prunedY)
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

Finds result interval for division of {a..b} / {c..d}
"""
function divBounds!(a::Int, b::Int, c::Int, d::Int)

    ac = a ÷ c
    ad = a ÷ d
    bc = b ÷ c
    bd = b ÷ d

    min, idx = Base.findmin([ac, ad, bc, bd])
    max, idx = Base.findmax([ac, ad, bc, bd])

    return min, max
end

"""
divBounds!(a::Int, b::Int, c::Int, d::Int)pruneDivision!(prunedVar::AbstractIntVar, numeratorVar::AbstractIntVar, denominatorVar::AbstractIntVar)

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
    minZ, maxZ = divBounds!(xDomain.min.value, xDomain.max.value, yDomain.min.value, yDomain.max.value)
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

    reminderMin, reminderMax = reminderBounds!(xDomain.min.value, xDomain.max.value, yDomain.min.value, yDomain.max.value)

    # If 0 in x.domain and z.domain, domain of x cannot be pruned 
    if !(Z0 & X0)
        minY, maxY = divBounds!(xDomain.min.value - reminderMax, xDomain.max.value -reminderMin, zDomain.min.value, zDomain.max.value)

        #If x and z have same sign, y is positive
        if (xDomain.min.value >= 0 & zDomain.min.value >= 0) || (xDomain.min.value <= 0 & zDomain.min.value <= 0)
            minY = 1

        #If x and z have opposite sign, y is negative
        elseif (xDomain.min.value >= 0 & zDomain.min.value <= 0) || (xDomain.min.value <= 0 & zDomain.min.value >= 0)
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

    minYZ, maxYZ = mulBounds!(yDomain.min.value, yDomain.max.value, zDomain.min.value, zDomain.max.value)

    # Test if we have more precise bounds for reminderMin and reminderMax
    reminderMin, reminderMax = reminderBounds!(xDomain.min.value, xDomain.max.value, yDomain.min.value, yDomain.max.value)

    rMin = xDomain.min.value - maxYZ
    rMax = xDomain.max.value - minYZ
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
    minZ, maxZ = reminderBounds!(xDomain.min.value, xDomain.max.value, yDomain.min.value, yDomain.max.value)
    prunedZ = vcat(removeBelow!(zDomain, minZ), removeAbove!(zDomain, maxZ))

    if !isempty(prunedZ)
        triggerDomainChange!(toPropagate, constraint.z)
        addToPrunedDomains!(prunedDomains, constraint.z, prunedZ)
    end
    
    # Prune y domain 

    XYmin, XYmax = divBounds!(xDomain.min.value, xDomain.max.value, yDomain.min.value, yDomain.max.value)

    minY, maxY = divBounds!(xDomain.min.value - zDomain.max.value, xDomain.max.value - zDomain.min.value, XYmin, XYmax)

    prunedY = vcat(removeBelow!(yDomain, minY), removeAbove!(yDomain, maxY))
    prunedY = vcat(prunedY0, prunedY)
            
    if !isempty(prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
    end

    # Prune x domain
    
    minX, maxX = mulBounds!(XYmin, XYmax, yDomain.min.value, yDomain.max.value)

    prunedX = vcat(removeBelow!(xDomain, minX + zDomain.min.value), removeAbove!(xDomain, maxX + zDomain.max.value))

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
using Distributions

struct GraphColoringGenerator <: AbstractModelGenerator
    nb_nodes::Int
    density::Real
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::GraphColoringGenerator)::CPModel    

Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose ! Density should be more than 1.
"""
function fill_with_generator!(cpmodel::CPModel, gen::GraphColoringGenerator)
    density = gen.density
    nb_nodes = gen.nb_nodes

    nb_edges = floor(Int64, density * nb_nodes)

    # create variables
    x = CPRL.IntVar[]
    for i in 1:nb_nodes
        push!(x, CPRL.IntVar(1, nb_nodes, string(i), cpmodel.trailer))
        addVariable!(cpmodel, last(x))
    end
    @assert nb_edges >= nb_nodes - 1
    connexions = [1 for i in 1:nb_nodes]
    # create Geometric distribution
    p = 2 / nb_nodes
    distr = Truncated(Geometric(p), 0, nb_nodes)
    new_connexions = rand(distr, nb_edges - nb_nodes)
    for new_co in new_connexions
        connexions[convert(Int64, new_co)] += 1
    end

    # should make sure that every node has less than nb_nodes - 1 connexions

    # edge constraints
    for i in 1:length(connexions)
        neighbors = sample([j for j in 1:length(connexions) if j != i && connexions[i] > 0], connexions[i], replace=false)
        for j in neighbors
            push!(cpmodel.constraints, CPRL.NotEqual(x[i], x[j], cpmodel.trailer))
        end
    end

    ### Objective ###
    numberOfColors = CPRL.IntVar(1, nb_nodes, "numberOfColors", cpmodel.trailer)
    CPRL.addVariable!(cpmodel, numberOfColors)
    for var in x
        push!(cpmodel.constraints, CPRL.LessOrEqual(var, numberOfColors, cpmodel.trailer))
    end
    cpmodel.objective = numberOfColors

    nothing
end

struct GraphColoringWithFileGenerator <: AbstractModelGenerator
    input_file::String
end

struct Edge
    vertex1     :: Int
    vertex2     :: Int
end

struct InputData
    edges               :: Array{Edge}
    numberOfEdges       :: Int
    numberOfVertices    :: Int
end

struct OutputData
    numberOfColors      :: Int
    edgeColors          :: Array{Int}
    optimality          :: Bool
end

include("IOmanager.jl")

function fill_with_generator!(model::CPModel, gen::GraphColoringWithFileGenerator)
    input_file = gen.input_file
    input = getInputData(input_file)

    trailer = model.trailer

    ### Variable declaration ###
    x = CPRL.IntVar[]
    for i in 1:input.numberOfVertices
        push!(x, CPRL.IntVar(1, input.numberOfVertices, string(i), trailer))
        CPRL.addVariable!(model, last(x))
    end

    ### Constraints ###
    # Breaking some symmetries
    push!(model.constraints, CPRL.EqualConstant(x[1], 1, trailer))
    push!(model.constraints, CPRL.LessOrEqual(x[1], x[2], trailer))

    # Edge constraints
    degrees = zeros(Int, input.numberOfVertices)
    for e in input.edges
        push!(model.constraints, CPRL.NotEqual(x[e.vertex1], x[e.vertex2], trailer))
        degrees[e.vertex1] += 1
        degrees[e.vertex2] += 1
    end
    sortedPermutation = sortperm(degrees; rev=true)

    ### Objective ###
    numberOfColors = CPRL.IntVar(1, input.numberOfVertices, "numberOfColors", trailer)
    CPRL.addVariable!(model, numberOfColors)
    for var in x
        push!(model.constraints, CPRL.LessOrEqual(var, numberOfColors, trailer))
    end
    model.objective = numberOfColors


    ### Variable selection heurstic ###
    function selectVariable(model::CPRL.CPModel, sortedPermutation, degrees)
        maxDegree = 0
        toReturn = nothing
        for i in sortedPermutation
            if !CPRL.isbound(model.variables[string(i)])
                if isnothing(toReturn)
                    toReturn = model.variables[string(i)]
                    maxDegree = degrees[i]
                end
                if degrees[i] < maxDegree
                    return toReturn
                end

                if length(model.variables[string(i)].domain) < length(toReturn.domain)
                    toReturn = model.variables[string(i)]
                end
            end
        end
        return toReturn
    end

    return ((m) -> selectVariable(m, sortedPermutation, degrees))
end
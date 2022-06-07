
"""
    abstract type CPLayerVertex end

A vertex that contains the CP "true" object.
"""
abstract type CPLayerVertex end

"""
    abstract type FixedEdgesVertex <: CPLayerVertex end

A vertex whose edges won't be modified during the solving.
"""
abstract type FixedEdgesVertex <: CPLayerVertex end

"""
    struct ValueVertex <: CPLayerVertex 

A vertex corresponding to the value of a domain, that is connected to
a variable only if the value is in the domain of that variable.
"""
struct ValueVertex <: CPLayerVertex 
    value       ::Int
end

"""
    struct ConstraintVertex <: CPLayerVertex 

A vertex corresponding to a constraint, that is connected to
a variable only if the constraint affects that variable.
"""
struct ConstraintVertex <: FixedEdgesVertex
    constraint  ::Constraint
end

"""
    struct VariableVertex <: CPLayerVertex 

A vertex corresponding to a variable, that is connected to
a constraint only if that constraint affects the variable,
and connected to a value only if that value is in the domain
of the variable.
"""
struct VariableVertex <: FixedEdgesVertex 
    variable    ::AbstractVar
end


"""
    struct CPLayerGraph <: AbstractGraph{Int}

Graph representing the current status of the CPModel.
It is a tripartite graph, linking 3 types of nodes: constraints, variables and values.
A constraint is connected to a variable if the constraint affects the variable.
A variable is connected to a value if the value is in the variable's domain.

Since the relations between constraints and variables are not modified during the solving,
they are stored in an inner graph, `fixedEdgesGraph`, that won't be edited after creation.
On the contrary, domains get pruned during the solving. To always keep an up-to-date representation,
none of the value-variables edges are stored, and everytime they're needed, they are gotten from
the `CPModel` directly, hence the "layer" in the name of the struct.

Each vertex is indexed by an integer, in a specific order. You first have the constraints,
then the variables and finally the values.
"""
struct CPLayerGraph <: LightGraphs.AbstractGraph{Int} 
    cpmodel                     ::Union{CPModel, Nothing}
    idToNode                    ::Array{CPLayerVertex}
    nodeToId                    ::Dict{CPLayerVertex, Int}
    fixedEdgesGraph             ::LightGraphs.Graph
    numberOfConstraints         ::Int
    numberOfVariables           ::Int
    numberOfValues              ::Int
    totalLength                 ::Int

    """
        function CPLayerGraph(cpmodel::CPModel)

    Create the graph corresponding to the CPModel.
    The graph gets linked to `cpmodel` and does not need to get updated by anyone when domains are pruned.
    """
    function CPLayerGraph(cpmodel::CPModel)
        variables = Set{AbstractVar}(values(cpmodel.variables))
        valuesOfVariables = sort(branchable_values(cpmodel))
        numberOfConstraints = length(cpmodel.constraints)
        numberOfValues = length(valuesOfVariables)

        variableConnections = Tuple{AbstractVar, AbstractVar}[]

        # Take into account IntVarViews that are only declared in constraints
        # Array listing constraints representing view relations between variables
        viewConstraints = []
        for constraint in cpmodel.constraints
            for constraintVar in variablesArray(constraint)
                while typeof(constraintVar) <: Union{IntVarView, BoolVarView}
                    push!(variables, constraintVar)

                    # Creating a new constraint and storing constraint-variable connections
                    viewcon = ViewConstraint(constraintVar.x, constraintVar)
                    push!(viewConstraints, viewcon)

                    constraintVar = constraintVar.x
                end
            end
        end
        variables = collect((variables))
        
        # We sort the variables by their id to get a consistent order
        sort!(variables; by=(x) -> x.id)
        
        numberOfVariables = length(variables)
        totalLength = numberOfConstraints + length(viewConstraints) + numberOfVariables + numberOfValues

        nodeToId = Dict{CPLayerVertex, Int}()
        idToNode = Array{CPLayerVertex}(undef, totalLength)

        # Filling constraints
        for i in 1:numberOfConstraints
            idToNode[i] = ConstraintVertex(cpmodel.constraints[i])
            nodeToId[ConstraintVertex(cpmodel.constraints[i])] = i
        end

        # Filling view constraints
        for i in 1:length(viewConstraints)
            idToNode[numberOfConstraints + i] = ConstraintVertex(viewConstraints[i])
            nodeToId[ConstraintVertex(viewConstraints[i])] = numberOfConstraints + i
        end

        numberOfConstraints += length(viewConstraints)
        
        # Filling variables
        for i in 1:numberOfVariables
            idToNode[numberOfConstraints + i] = VariableVertex(variables[i])
            nodeToId[VariableVertex(variables[i])] = numberOfConstraints + i
        end

        # Filling values
        for i in 1:numberOfValues
            idToNode[numberOfConstraints + numberOfVariables + i] = ValueVertex(valuesOfVariables[i])
            nodeToId[ValueVertex(valuesOfVariables[i])] = numberOfConstraints + numberOfVariables + i
        end

        
        fixedEdgesGraph = Graph(numberOfConstraints + numberOfVariables)
        for id in 1:numberOfConstraints
            constraint = idToNode[id].constraint
            varArray = variablesArray(constraint)
            for x in varArray
                if x.id != "SEAPEARL_one"
                    add_edge!(fixedEdgesGraph, id, nodeToId[VariableVertex(x)])
                end
            end
        end

        return new(cpmodel, idToNode, nodeToId, fixedEdgesGraph, numberOfConstraints, numberOfVariables, numberOfValues, totalLength)
    end

    """
        function CPLayerGraph()

    Create an empty graph, needed to implement the `zero` function for the LightGraphs.jl interface.
    """
    function CPLayerGraph()
        return new(nothing, CPLayerVertex[], Dict{CPLayerVertex, Int}(), Graph(0), 0, 0, 0, 0)
    end
end


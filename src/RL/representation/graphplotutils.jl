"""
    Utils allowing to understand and get insight about the tripartite graph representing the problem that we are solving.
    To use these functions, call them in defaultstaterepresentation.jl or heterogeneousstaterepresentation.jl
    These functions aren't called by default.
"""

using Plots
using GraphPlot
using Cairo, Compose
import Graphs

function plottripartite(sr::Union{DefaultStateRepresentation, HeterogeneousStateRepresentation})
    cpmodel = sr.cplayergraph
    am = Matrix(adjacency_matrix(cpmodel))
    n = cpmodel.totalLength
    nodefillc = []
    label = []
    for id in 1:n
        v = cpmodel.idToNode[id]
        if isa(v, VariableVertex) 
            push!(nodefillc,"red")
            push!(label,v.variable.id)
        elseif isa(v, ValueVertex)
            push!(nodefillc,"blue")
            push!(label,v.value)
        else  
            push!(nodefillc,"black")
            push!(label,typeof(v.constraint))
        end
    end
    draw(PDF("plot.pdf", 16cm, 16cm), gplot(Graphs.Graph(am); nodefillc=nodefillc, nodelabel=label))
    error("Your plot is ready")
end

function default_graph_stats(adj)
    g = Graph(adj)
    println("Number of vertices: "* string(nv(g)))
    println("Number of edges: "* string(ne(g)))
    println("Density of the graph: "* string(LightGraphs.density(g)))
end

function heterogeneous_graph_stats(adj, varnf, connf, valnf)
    g = Graph(adj)
    println("Number of vertices: "* string(nv(g)))
    println("Number of edges: "* string(ne(g)))
    println("Density of the graph: "* string(LightGraphs.density(g)))
    println("Number of variable nodes: "* string(size(varnf)[2]))
    println("Number of constraint nodes: "* string(size(connf)[2]))
    println("Number of value nodes: "* string(size(valnf)[2]))
end
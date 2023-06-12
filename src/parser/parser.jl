include("constraints/constraints.jl")
include("utils/xml_utils.jl")
include("variables.jl")
include("objective.jl")

"""
    parse_xml_file(file_path::AbstractString)

Parse the XCSP3 instance file located at `file_path` and return a tuple containing the model, the trailer and a dictionary containing the variables
"""
function parse_xml_file(file_path::AbstractString)
    # Convert document into XML node 
    doc = XML.read(file_path, XML.Node)

    # Get instance node
    instance = find_element(doc, "instance")

    # Get variables, constraints and objective node 
    variables = find_element(instance, "variables")
    constraints = find_element(instance, "constraints")
    objectives = find_element(instance, "objectives")

    #Create model
    trailer = SeaPearl.Trailer()
    model = SeaPearl.CPModel(trailer)

    #Variables parsing 
    
    if !isnothing(variables)
        dict_variables = parse_all_variables(variables, model, trailer)
    else 
        dict_variables = Dict{String,Any}()
    end

    #Constraints parsing 
    if !isnothing(constraints)
        parse_all_constraints(constraints, dict_variables, model, trailer)
    end

    #Objective parsing 
    if !isnothing(objectives)
        parse_objective_function(objectives, dict_variables, model, trailer)
    end
    
    return model, trailer, dict_variables
end


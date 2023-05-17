function parse_element_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    str_list  = get_node_string(find_element(constraint, "list"))

    if isnothing(find_element(constraint, "index"))
        println("Error - index node must be defined")

    else
        str_relation = get_node_string(find_element(constraint, "condition"))
        str_index = get_node_string(find_element(constraint, "index"))
        str_starting_index = get_starting_index()
        parse_element_constraint_expression(str_relation, str_list, str_index, str_starting_index, variables, model, trailer)
    end
    
end

function parse_element_constraint_expression(str_relation::String,
    str_list::String, 
    str_index::String, 
    str_starting_index::String,
    variables::Dict{String, Any}, 
    model::SeaPearl.CPModel, 
    trailer::SeaPearl.Trailer)

    list = nothing
    index = nothing
    operator = nothing
    right_operand = nothing

    if !isnothing(str_list)
        list = get_list_expression(str_list, variables)
    else
        println("Error - list node is not defined")
    end
    if !isnothing(str_index)
        index = get_index_expression(str_index, str_starting_index, variables)
    else
        println("Error - index node is not defined")
    end

    if !isnothing(str_relation)
        operator, right_operand = get_relation_element_expression(str_relation, variables)
    else
        println("Error - condition node is not defined")
    end

    if operator != "eq"
        println("Error - operator is not 'eq'")
    end
    if !isa(index, SeaPearl.AbstractIntVar)
        println("Error - index is not an AbstractIntVar")
    end
    if !isa(right_operand, SeaPearl.AbstractIntVar)
        println("Error - right operand is not an AbstractIntVar")
    end

    if (all(x -> isa(x, Int), list)) && (operator == "eq") && (isa(index, SeaPearl.AbstractIntVar)) && (isa(right_operand, SeaPearl.AbstractIntVar))
        con = SeaPearl.Element1D(list, index, right_operand, trailer)
        SeaPearl.addConstraint!(model, con)
    elseif (all(x -> isa(x, SeaPearl.AbstractIntVar), list)) && (operator == "eq") && (isa(index, SeaPearl.AbstractIntVar)) && (isa(right_operand, SeaPearl.AbstractIntVar))
        con = SeaPearl.Element1DVar(list, index, right_operand, trailer)
        SeaPearl.addConstraint!(model, con)
    else
        println("Error -list is neither made of Int or AbstractIntVar or operator != 'eq' or index is not an AbstractIntVar or the right operand is not an AbstractIntVar")
    end
end


function get_relation_element_expression(str_relation::String, variables)
    value = 0
    relation = ""

    relation = match(r"\((\w+),(-?\S+)\)", str_relation).captures[1]

    if relation in ["lt","le","gt","ge","eq","ne"]
        if is_digit(match(r"\((\w+),(-?\S+)\)", str_relation)[2])
            # Value is a Int
            value = parse(Int, match(r"\((\w+),(-?\d+)\)", str_relation).captures[2])
        else
            # value is a variable
            id_var = match(r"\((\w+),(\S+)\)", str_relation)[2]
            value = get_list_expression(id_var, variables)[1]
        end
    else
        println("Error - Relation not in [lt, le, gt, ge, eq, ne]")
    end
    return relation, value
end

function get_index_expression(str_index::String, str_starting_index::String, variables::Dict{String, Any})
    index = nothing
    if str_starting_index == "0"
        if is_digit(str_index)
            println("index is a digit, it must be an AbstractIntVar")
            # index = parse(Int, str_index) + 1
        else
            index = get_list_expression(str_index, variables)[1]
        end
    elseif str_starting_index == "1"
        if is_digit(str_index)
            println("index is a digit, it must be an AbstractIntVar")
            # index = parse(Int, str_index)
        else
            index = get_list_expression(str_index, variables)[1]
        end
    elseif str_starting_index == ""
        if is_digit(str_index)
            println("index is a digit, it must be an AbstractIntVar")
            # index = parse(Int, str_index) + 1
        else
            index = get_list_expression(str_index, variables)[1]
        end
    elseif isnothing(str_starting_index)
        if is_digit(str_index)
            println("index is a digit, it must be an AbstractIntVar")
            # index = parse(Int, str_index) + 1
        else
            index = get_list_expression(str_index, variables)[1]
        end
    else
        println("Error - index not recognized")
    end
    return index
end

function get_value_expression(str_value::String, variables::Dict{String, Any})
    value = 0
    if is_digit(str_value)
        value = parse(Int, str_value)
    else
        value = variables[str_value]
    end
    return value
end


function get_list_expression(str_list, variables)
    constraint_variables = SeaPearl.IntVar[]
    array_value = Int[]

    for str_l in split(str_list, " ")
        # Delete "]"
        str = replace(str_l, "]" => "")
            
        # Divide string into array of substring
        str_vector = split(str, "[")

        id, str_idx = str_vector[1], str_vector[2:end]

        #Get array with id
        if is_digit(id)
            push!(array_value, parse(Int, id))
        else
            var = variables[id]

            int_idx = []
            for i in str_idx
                #All index have to be considered
                if i == ""
                    push!(int_idx, [:][1])
                else
                    bounds = split(i, "..")
                    lower_bound = parse(Int, bounds[1]) + 1

                    #A subset from the array is considered
                    if length(bounds) == 2
                        upper_bound = parse(Int, bounds[2]) + 1
                        push!(int_idx, [lower_bound:upper_bound][1])
                    
                    #Only one index is considered
                    else
                        push!(int_idx, lower_bound)
                    end
                end
            end
            
            vars = var[int_idx...]
            if isa(vars, Array)
                push!(constraint_variables, vars...)
            else
                push!(constraint_variables, vars)
            end
        end
    end

    if !isempty(array_value)
        return array_value
    else
        return constraint_variables
    end
    return constraint_variables
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

function get_starting_index()
    startingIdex = "0" # only true for XCSP 2023
    return startingIdex
end

const sum_constant_operators = Dict(
    "lt" => (variables, value, trailer) -> SeaPearl.SumLessThan(variables, value-1, trailer),
    "le" => (variables, value, trailer) -> SeaPearl.SumLessThan(variables, value, trailer),
    "ge" => (variables, value, trailer) -> SeaPearl.SumGreaterThan(variables, value, trailer),
    "gt" => (variables, value, trailer) -> SeaPearl.SumGreaterThan(variables, value+1, trailer),
    "eq" => (variables, value, trailer) -> SeaPearl.SumToConstant(variables, value, trailer)
)

const sum_variable_operators = Dict(
    "lt" => (variables, trailer) -> SeaPearl.SumLessThan(variables, -1, trailer),
    "le" => (variables, trailer) -> SeaPearl.SumLessThan(variables, 0, trailer),
    "ge" => (variables, trailer) -> SeaPearl.SumGreaterThan(variables, 0, trailer),
    "gt" => (variables, trailer) -> SeaPearl.SumGreaterThan(variables, 1, trailer),
    "eq" => (variables, trailer) -> SeaPearl.SumToZero(variables, trailer)
)

"""
    parse_sum_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse a sum constraint
"""
function parse_sum_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    str_relation  = get_node_string(find_element(constraint, "condition"))
    str_list  = get_node_string(find_element(constraint, "list"))

    coeffs_node = find_element(constraint, "coeffs")
    if isnothing(coeffs_node)
        str_coeffs = ""
    else 
        str_coeffs = get_node_string(coeffs_node)
    end
    parse_sum_constraint_expression(str_relation, str_list, str_coeffs, variables, model, trailer)
end

"""
    parse_sum_constraint_expression(str_relation::String, str_list::String, str_coeffs::String, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse a sum constraint expression
"""
function parse_sum_constraint_expression(str_relation::String, str_list::String, str_coeffs::String, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    constraint_variables = get_constraint_variables_expression(str_list, str_coeffs, variables)
    operator, operand = get_relation_sum_expression(str_relation, variables)

    if operator == "ne"
        parse_notEqual_sum_expression(operand, constraint_variables, model, trailer)
    else
        if typeof(operand) == Int
            constraint = sum_constant_operators[operator]
            SeaPearl.addConstraint!(model, constraint(constraint_variables, operand, trailer))
        else
            new_constraint_variables = vcat(constraint_variables, [SeaPearl.IntVarViewOpposite(operand, "-"*operand.id)])
    
            constraint = sum_variable_operators[operator]
            SeaPearl.addConstraint!(model, constraint(new_constraint_variables, trailer))
        end
    end
end
    
    
"""
    parse_notEqual_sum_expression(operand::Any, constraint_variables::Vector{<:SeaPearl.AbstractIntVar}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse a sum constraint expression with a not equal operator
"""
function parse_notEqual_sum_expression(operand::Any, constraint_variables::Vector{<:SeaPearl.AbstractIntVar}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    # add the variable y, add the constraint "y = sum" ,
    # add the constraint "y != value"(notequal.jl)
    sum_min = 0
    sum_max = 0

    name_sum = "sum("
    for var in constraint_variables
        sum_min += minimum(var.domain)
        sum_max += maximum(var.domain)
        name_sum *= var.id*","
    end
    name_sum = name_sum[1:end-1]*")"

    #Operand is an Int
    if typeof(operand) == Int
        y = SeaPearl.IntVar(sum_min, sum_max, name_sum*"!="*string(operand), trailer)
        con_y = SeaPearl.NotEqualConstant(y, operand, trailer)

    #Operand is an IntVar
    else
        y = SeaPearl.IntVar(sum_min, sum_max, name_sum*"!="*operand.id, trailer)
        con_y = SeaPearl.NotEqual(y, operand, trailer)
    end
    con_sum = SeaPearl.SumToVariable(constraint_variables, y, trailer)
    SeaPearl.addConstraint!(model, con_y)
    SeaPearl.addConstraint!(model, con_sum)
end


function get_constraint_variables_expression(str_list::AbstractString, str_coeffs::AbstractString, variables::Dict{String, Any})
    constraint_variables = SeaPearl.AbstractIntVar[]
    list_var = get_constraint_variables(str_list, variables)
    list_coeff = get_coefficients_expression(str_coeffs, length(list_var))

    if length(list_var) == length(list_coeff)
        for i in 1:length(list_var)
            var = list_var[i]
            if str_coeffs == ""
                push!(constraint_variables, var)
            else
                coeff = list_coeff[i]
                id = string(coeff) * string(var.id)
                if coeff > 0 
                    var_mul = SeaPearl.IntVarViewMul(var, coeff, id)
                elseif coeff == 0 
                    continue
                else
                    var_opposite = SeaPearl.IntVarViewOpposite(var, "-" * string(var.id))
                    var_mul = SeaPearl.IntVarViewMul(var_opposite, -coeff, id)
                end
                push!(constraint_variables, var_mul)
            end
            
        end
    else
        error("Numbers of variables and coefficients are not the same")
    end
    return constraint_variables
end

function get_coefficients_expression(str_coeffs::AbstractString, nb_variables::Int)
    coeffs_list = []

    # if there are variables but no coeffiecients, by default the coeffs are put to 1
    if str_coeffs == ""
        for i in 1:nb_variables
            push!(coeffs_list, 1)
        end
        return coeffs_list
    else
        for str_variable in split(str_coeffs, " ")
            # Case matrix of coeff : NumberxNumber
            if occursin("x", str_variable)
                idx_x = findfirst("x", str_variable)
                coeff_str = str_variable[1:idx_x[1]-1]
                coeff = parse(Int64, coeff_str)
                nb_coef_str = str_variable[idx_x[1]+1:end]
                nb_coef = parse(Int64, nb_coef_str)
                coeff_arr = coeff * ones(Int64, nb_coef)
                push!(coeffs_list, coeff_arr)
            # Case coeff Number
            else
                coeff = parse(Int64, str_variable)
                push!(coeffs_list, [coeff])
            end
        end
    end

    return reduce(vcat, coeffs_list)
end

function get_relation_sum_expression(str_relation::String, dict_variables::Dict{String, Any})
    str_operator, str_operand = split(str_relation[2:end-1], ",")
    
    if str_operator in ["lt","le","gt","ge","eq","ne"]
        if is_digit(str_operand)
            # operand is an Int
            operand = parse(Int, str_operand)
        else
            # operand is an IntVar
            operand = get_constraint_variables(str_operand, dict_variables)[1]
        end
    else
        error("Operator $str_operator in sum constraint does not exist.")
    end
    return str_operator, operand
end
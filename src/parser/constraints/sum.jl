

function parse_sum_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    str_relation  = get_node_string(find_element(constraint, "condition"))
    str_list  = children(find_element(constraint, "list"))[1].value

    if isnothing(find_element(constraint, "coeffs"))
        str_coeffs = ""
    else 
        str_coeffs = children(find_element(constraint, "coeffs"))[1].value
    end
    parse_sum_constraint_expression(str_relation, str_list, str_coeffs, variables, model, trailer)
end

function parse_sum_constraint_expression(str_relation::String, str_list::String, str_coeffs::String, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    vars = get_constraint_variables_expression(str_list, str_coeffs, variables)
    operator, value = get_relation_sum_expression(str_relation, variables)
    # 'value' is an array (one per sum constraints) of an array with 1 value in the general case 
    # and 2 value in case of relation operand 'in'

    if operator == "lt"
        con = con = SeaPearl.SumLessThan(vars, value-1, trailer)
        SeaPearl.addConstraint!(model, con)

    elseif operator == "le"
        con = SeaPearl.SumLessThan(vars, value, trailer)
        SeaPearl.addConstraint!(model, con)

    elseif operator == "gt"
        con = con = SeaPearl.SumGreaterThan(vars, value+1, trailer)
        SeaPearl.addConstraint!(model, con)

    elseif operator == "ge"
        con = SeaPearl.SumGreaterThan(vars, value, trailer)
        SeaPearl.addConstraint!(model, con)

    elseif operator == "eq"
        con_sum = SeaPearl.SumToConstant(vars, value, trailer)
        SeaPearl.addConstraint!(model, con_sum)

    elseif operator == "ne"
        # add the variable y, add the constraint "y = sum" ,
        # add the constraint "y != value"(notequal.jl)
        min_vars = []
        max_vars = []

        name_sum = "sum("
        for i in vars
            push!(min_vars, minimum(i.domain.orig)*i.a)
            push!(max_vars, maximum(i.domain.orig)*i.a)
            name_sum *= i.id*","
        end
        name_sum = name_sum[1:end-1]*")"
        sum_min_bound = sum(min_vars)
        sum_max_bound = sum(max_vars)

        y = SeaPearl.IntVar(sum_min_bound, sum_max_bound, name_sum*"!="*string(value), trailer)


        con_y = SeaPearl.NotEqualConstant(y, value, trailer)
        con_sum = SeaPearl.SumToVariable(vars, y, trailer)
        SeaPearl.addConstraint!(model, con_y)
        SeaPearl.addConstraint!(model, con_sum)

    else
        error("Relation Unknown")
    end
end


function get_constraint_variables_expression(str_list, str_coeffs, variables)
    constraint_variables = SeaPearl.AbstractIntVar[]


    list_var, variables_but_no_coeffs = get_list_expression(str_list, variables)
    list_coeff = get_coefficients_expression(str_coeffs, variables_but_no_coeffs)

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

function get_coefficients_expression(str_coeffs, nb_variables)
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


function get_list_expression(str_list, variables)
    constraint_variables = SeaPearl.IntVar[]

    for str_variable in split(str_list, " ")

        # Delete "]"
        str = replace(str_variable, "]" => "")
            
        # Divide string into array of substring
        str_vector = split(str, "[")

        id, str_idx = str_vector[1], str_vector[2:end]


        #Get array with id
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
    return constraint_variables, length(constraint_variables) #, variables_but_no_coeffs
end


function get_relation_sum_expression(str_relation::String, dict_variables::Dict{String, Any})
    str_operator, str_operand = split(str_relation[2:end-1], ",")
    
    if str_operator in ["lt","le","gt","ge","eq","ne"]
        if is_digit(str_operand)
            # operand is an Int
            operand = parse(Int, str_operands)
        else
            # operand is an IntVar
            operand = get_constraint_variables(str_operands, dict_variables)[1]
        end
    else
        error("Operator $str_operator in sum constraint does not exist.")
    end
    return str_operator, operand
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
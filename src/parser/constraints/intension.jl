const relational_constant_operators = Dict(
    "lt" => SeaPearl.LessConstant,
    "le" => SeaPearl.LessOrEqualConstant,
    "ge" => SeaPearl.GreaterOrEqualConstant,
    "gt" => SeaPearl.GreaterConstant,
    "ne" => SeaPearl.NotEqualConstant,
    "eq" => SeaPearl.EqualConstant,
)

const relational_variable_operators = Dict(
    "lt" => SeaPearl.Less,
    "le" => SeaPearl.LessOrEqual,
    "ge" => SeaPearl.GreaterOrEqual,
    "gt" => SeaPearl.Greater,
    "ne" => SeaPearl.NotEqual,
    "eq" => SeaPearl.Equal,
)

const arithmetic_operators = Dict(
    "add" => SeaPearl.Addition,
    "sub" => SeaPearl.Subtraction,
    "mul" => SeaPearl.Multiplication,
    "div" => SeaPearl.Division,
    "mod" => SeaPearl.Modulo,
    "dist" => SeaPearl.Distance,
)

function parse_intension_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    str_constraint = get_node_string(constraint)
    parse_intension_expression(str_constraint, variables, model, trailer)
end

function parse_intension_expression(str_constraint::String, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    # Split the expression into operator and operands
    spl = split(str_constraint, "(", limit=2)
    operator = spl[1]
    ari_bool = haskey(arithmetic_operators, operator)
    rel_bool = !ari_bool

    # If the expression does not have any further parentheses, return it as a variable or a value
    if !(rel_bool || ari_bool)
        
        #The expression is a constant
        if is_digit(str_constraint)
            value = parse(Int, str_constraint)
            return value
        else
            var = get_constraint_variables(str_constraint, variables)[1]
            return var
        end
    end
    
    operands_str = string(spl[2])[1:end-1]
    # Recursively parse the operands
    start = 1
    balance = 0
    var1 = nothing
    for i = 1:length(operands_str)
        char = operands_str[i]
        if char == '('
            balance += 1
        elseif char == ')'
            balance -= 1
        elseif char == ',' && balance == 0
            var1 = parse_intension_expression(operands_str[start:i-1], variables, model, trailer)
            start = i + 1
            break
        end
    end
    var2 = parse_intension_expression(operands_str[start:end], variables, model, trailer)

    if rel_bool
        if isa(var2, Int)
            constraint = relational_constant_operators[operator]
        else
            constraint = relational_variable_operators[operator]
        end
        SeaPearl.addConstraint!(model, constraint(var1, var2, trailer))
        return nothing
        
    else
        new_var = create_arithmetic_variable(var1, var2, string(operator), trailer)
        SeaPearl.addVariable!(model, new_var)

        constraint = arithmetic_operators[operator]
        SeaPearl.addConstraint!(model, constraint(var1, var2, new_var, trailer))
        return new_var
    end
end


function create_arithmetic_variable(x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar, operator::String, trailer::SeaPearl.Trailer)
    xMin = x.domain.min.value
    xMax = x.domain.max.value

    yMin = y.domain.min.value
    yMax = y.domain.max.value

    if operator == "add"
        zMin, zMax = xMin + yMin, xMax + yMax
        return SeaPearl.IntVar(zMin, zMax, "(" * x.id * "+" * y.id * ")", trailer)
    end

    if operator == "sub"
        zMin, zMax = xMin - yMax, xMax - yMin
        return SeaPearl.IntVar(zMin, zMax, "(" * x.id * "-" * y.id * ")", trailer)
    end

    if operator == "mul"
        zMin, zMax = SeaPearl.mulBounds!(xMin, xMax, yMin, yMax)
        return SeaPearl.IntVar(zMin, zMax, "(" * x.id * "*" * y.id * ")", trailer)
    end

    if operator == "div"
        zMin, zMax = SeaPearl.divBounds!(xMin, xMax, yMin, yMax)
        return SeaPearl.IntVar(zMin, zMax, "(" * x.id * "÷" * y.id * ")", trailer)
    end

    if operator == "mod"
        zMin, zMax = SeaPearl.reminderBounds!(xMin, xMax, yMin, yMax)
        return SeaPearl.IntVar(zMin, zMax, "(" * x.id * "mod" * y.id * ")", trailer)
    end

    if operator == "dist"
        zMin, zMax = SeaPearl.distanceBounds!(xMin, xMax, yMin, yMax)
        return SeaPearl.IntVar(zMin, zMax, "|" * x.id * "-" * y.id * "|", trailer)
    end
end

function is_digit(str::AbstractString)
    for c in str
        if !isdigit(c)
            return false
        end
    end
    return true
end
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

"""
    parse_intension_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse an intension constraint
"""
function parse_intension_constraint(constraint::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    str_constraint = get_node_string(constraint)
    parse_intension_expression(str_constraint, variables, model, trailer)
end

"""
    parse_intension_expression(str_constraint::AbstractString, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)

Parse an intension expression
"""
function parse_intension_expression(str_constraint::AbstractString, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    # Split the expression into operator and operands
    spl = split(str_constraint, "(", limit=2)
    operator = spl[1]
    ari_bool = haskey(arithmetic_operators, operator)
    rel_bool = haskey(relational_constant_operators, operator) || haskey(relational_variable_operators, operator)

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
        if !haskey(model.variables, new_var.id)
            SeaPearl.addVariable!(model, new_var)
        else
            new_var = model.variables[new_var.id]
        end

        # Do not add constraint if add(x,k), sub(x,k), mul(x,k) with k Integer
        if isa(var1, Int) || isa(var2, Int)
            if !(operator in ["add", "sub", "mul"])
                if isa(var1, Int)
                    var1 = SeaPearl.IntVar(var1, var1, string(var1), trailer)
                else
                    var2 = SeaPearl.IntVar(var2, var2, string(var2), trailer)
                end
                constraint = arithmetic_operators[operator]
                SeaPearl.addConstraint!(model, constraint(var1, var2, new_var, trailer))
            end
        else
            constraint = arithmetic_operators[operator]
            SeaPearl.addConstraint!(model, constraint(var1, var2, new_var, trailer))
        end
        
        return new_var
    end
end

"""
    create_arithmetic_variable(x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar, operator::String, trailer::SeaPearl.Trailer)

Create a new variable from the arithmetic operation of two variables : x operator y
"""
function create_arithmetic_variable(x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar, operator::String, trailer::SeaPearl.Trailer)
    xMin = minimum(x.domain)
    xMax = maximum(x.domain)

    yMin = minimum(y.domain)
    yMax = maximum(y.domain)

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

"""
    create_arithmetic_variable(x::SeaPearl.AbstractIntVar, k::Int, operator::String, trailer::SeaPearl.Trailer)

Create a new variable from the arithmetic operation of one variable x and one integer k : x operator k
"""
function create_arithmetic_variable(x::SeaPearl.AbstractIntVar, k::Int, operator::String, trailer::SeaPearl.Trailer)
    xMin = minimum(x.domain)
    xMax = maximum(x.domain)

    if operator == "add"
        return SeaPearl.IntVarViewOffset(x, k, "(" * x.id * "+$k)")
    end

    if operator == "sub"
        return SeaPearl.IntVarViewOffset(x, -k, "(" * x.id * "-$k)")
    end

    if operator == "mul"
        if k >= 0
            return SeaPearl.IntVarViewMul(x, k, "($k*" * x.id * ")")
        else
            return SeaPearl.IntVarViewMul(Seapearl.IntVarViewOpposite(x, "-"* x.id), -k, "($k" * x.id * ")")
        end
    end

    if operator == "div"
        zMin, zMax = SeaPearl.divBounds!(xMin, xMax, k, k)
        return SeaPearl.IntVar(zMin, zMax, "(" * x.id * "÷$k)", trailer)
    end

    if operator == "mod"
        zMin, zMax = SeaPearl.reminderBounds!(xMin, xMax, k, k)
        return SeaPearl.IntVar(zMin, zMax, "(" * x.id * " mod $k)", trailer)
    end

    if operator == "dist"
        zMin, zMax = SeaPearl.distanceBounds!(xMin, xMax, k, k)
        return SeaPearl.IntVar(zMin, zMax, "|" * x.id * "-$k|", trailer)
    end
end


"""
    create_arithmetic_variable(k::Int, x::SeaPearl.AbstractIntVar, operator::String, trailer::SeaPearl.Trailer)

Create a new variable from the arithmetic operation of one integer k and one variable x : k operator x
"""
function create_arithmetic_variable(k::Int, x::SeaPearl.AbstractIntVar, operator::String, trailer::SeaPearl.Trailer)
    xMin = minimum(x.domain)
    xMax = maximum(x.domain)

    if operator == "add"
        return SeaPearl.IntVarViewOffset(x, k, "(" * x.id * "+$k)")
    end

    if operator == "sub"
        return SeaPearl.IntVarViewOffset(Seapearl.IntVarViewOpposite(x, "-"* x.id), k, "($k-" * x.id * ")")
    end

    if operator == "mul"
        if k >= 0
            return SeaPearl.IntVarViewMul(x, k, "($k*" * x.id * ")")
        else
            return SeaPearl.IntVarViewMul(Seapearl.IntVarViewOpposite(x, "-"* x.id), -k, "($k*" * x.id * ")")
        end
    end

    if operator == "div"
        zMin, zMax = SeaPearl.divBounds!(k, k, xMin, xMax)
        return SeaPearl.IntVar(zMin, zMax, "($k÷" * x.id * ")", trailer)
    end

    if operator == "mod"
        zMin, zMax = SeaPearl.reminderBounds!(k, k, xMin, xMax)
        return SeaPearl.IntVar(zMin, zMax, "($k mod " * x.id * ")", trailer)
    end

    if operator == "dist"
        zMin, zMax = SeaPearl.distanceBounds!(k, k, xMin, xMax)
        return SeaPearl.IntVar(zMin, zMax, "|$k-" * x.id * "|", trailer)
    end
end
function parse_group(group::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    pattern_constraint, constraint_variables = children(group)[1], children(group)[2:end]

    tag = pattern_constraint.tag

    pattern = children(pattern_constraint)[1].value

    if tag == "intension"
        for con_vars in constraint_variables
            str_vars = split(children(con_vars)[1].value, " ")

            filled_pattern = pattern
            for (i, var) in enumerate(str_vars)
                filled_pattern = replace(filled_pattern, "%" * string(i-1) => string(var))
            end
            
            parse_intension_expression(filled_pattern, variables, model, trailer)
        end
    end

    
end
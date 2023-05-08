include("allDifferent.jl")
include("intension.jl")
include("group.jl")
include("extension.jl")
include("sum.jl")

include("../utils/xml_utils.jl")

function parse_all_constraints(constraints::Node, variables::Dict{String, Any}, model::SeaPearl.CPModel, trailer::SeaPearl.Trailer)
    
    for con in children(constraints)
        tag = con.tag
        if tag == "allDifferent"
            parse_allDifferent_constraint(con, variables, model, trailer)
        end

        if tag == "intension"
            parse_intension_constraint(con, variables, model, trailer)
        end

        if tag == "group"
            parse_group(con, variables, model, trailer)
        end

        if tag == "block"
            parse_all_constraints(con, variables, model, trailer)
        end

        if tag == "extension"
            parse_extension_constraint(con, variables, model, trailer)
        end

        if tag == "sum"
            parse_sum_constraint(con, variables, model, trailer)
        end

    end
end
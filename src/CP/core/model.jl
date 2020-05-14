struct CPModel
    variables       ::Dict{String, IntVar}
    constraints     ::Array{Constraint}
    CPModel() = new(Dict{String, IntVar}(), Constraint[])
end

"""
    addVariable!(model::CPModel, x::IntVar)

Add a variable to the model, throwing an error if `x`'s id is already in the model.
"""
function addVariable!(model::CPModel, x::IntVar)
    # Ensure the id is unique
    @assert !haskey(model.variables, x.id)

    model.variables[x.id] = x
end
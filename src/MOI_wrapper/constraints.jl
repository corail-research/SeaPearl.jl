# """
#     MOI.add_constraint(model::Optimizer, sgvar::MOI.VectorOfVariables, set::VariablesEquality)

# Interface function which add a constraint to the model (which is himself an Optimizer)
# This constraints a single variable to be different or equal to another variable.
# """
function MOI.add_constraint(model::Optimizer, vectOfVar::MOI.VectorOfVariables, ::NotEqualSet)
    id1, id2 = vectOfVar.variables[1], vectOfVar.variables[2]

    ci = MOI.ConstraintIndex{MOI.VectorOfVariables, NotEqualSet}(length(model.moimodel.constraints) + 1)
    moiConstraint = MOIConstraint(NotEqualSet, (id1, id2), ci)
    push!(model.moimodel.constraints, moiConstraint)

    
    return ci
end

function create_CPConstraint(moiconstraint::MOIConstraint{NotEqualSet}, optimizer::Optimizer)
    id1, id2 = moiconstraint.args
    x, y = get_cp_variable(optimizer, id1), get_cp_variable(optimizer, id2)
    NotEqual(x, y, optimizer.cpmodel.trailer)
end

"""
    MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::MOI.LessThan)

Interface function which add a constraint to the model (which is himself an Optimizer).
This constraints a single variable to be less than a given Integer.  
"""
function MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::MOI.LessThan{Float64})
    # get the VariableIndex and convert it to string
    id = sgvar.variable.value
    if isnothing(model.moimodel.variables[id].max) || model.moimodel.variables[id].max >= set.upper
        model.moimodel.variables[id].max = set.upper
    end
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{Float64}}(1)
end

function MOI.add_constraint(model::Optimizer, saf::MOI.ScalarAffineFunction{Float64}, set::MOI.LessThan{Float64})
    if length(saf.terms) != 2 || saf.terms[1].coefficient != 1. || saf.terms[2].coefficient != -1. || saf.constant != set.upper
        moiaff = MOIAffineFunction(nothing, saf)
        push!(model.moimodel.affines, moiaff)

        newId = length(model.moimodel.constraints) + 1
        ci = MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64}, MOI.LessThan{Float64}}(newId)
        constraint = MOIConstraint(SeaPearl.LessOrEqualConstant, (AffineIndex(length(model.moimodel.affines)), set.upper), ci)
        push!(model.moimodel.constraints, constraint)

        return ci
    
    end

    saf.constant -= set.upper
    
    

    newId = length(model.moimodel.constraints) + 1
    ci = MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64}, MOI.LessThan{Float64}}(newId)
    constraint = MOIConstraint(SeaPearl.LessOrEqual, (saf.terms[1].variable_index, saf.terms[2].variable_index), ci)
    push!(model.moimodel.constraints, constraint)

    return ci
end

function create_CPConstraint(moiconstraint::MOIConstraint{SeaPearl.LessOrEqual}, optimizer::Optimizer)
    if !isa(moiconstraint.ci, MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64}, MOI.LessThan{Float64}})
        return nothing
    end
    x = get_cp_variable(optimizer, moiconstraint.args[1])
    y = get_cp_variable(optimizer, moiconstraint.args[2])
    
    
    LessOrEqual(x, y, optimizer.cpmodel.trailer)
end

function create_CPConstraint(moiconstraint::MOIConstraint{SeaPearl.LessOrEqualConstant}, optimizer::Optimizer)
    x = get_cp_variable(optimizer, moiconstraint.args[1])
    c = Int(floor(moiconstraint.args[2]))

    removeAbove!(x.domain, c)
    nothing
end

"""
    MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::MOI.GreaterThan)

Give an upper bound to `sgvar` 
"""
function MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::MOI.GreaterThan{Float64})
    # get the VariableIndex and convert it to string
    id = sgvar.variable.value
    if isnothing(model.moimodel.variables[id].min) || model.moimodel.variables[id].min <= set.lower
        model.moimodel.variables[id].min = set.lower
    end
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{Float64}}(1)
end

function MOI.add_constraint(model::Optimizer, saf::MOI.ScalarAffineFunction{Float64}, set::MOI.EqualTo{Float64})
    saf.constant -= set.value
    moiaff = MOIAffineFunction(nothing, saf)
    push!(model.moimodel.affines, moiaff)

    newId = length(model.moimodel.constraints) + 1
    ci = MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64}, MOI.EqualTo{Float64}}(newId)
    constraint = MOIConstraint(MOI.EqualTo, (AffineIndex(length(model.moimodel.affines)),), ci)
    push!(model.moimodel.constraints, constraint)

    return ci
end

function create_CPConstraint(moiconstraint::MOIConstraint{MOI.EqualTo}, optimizer::Optimizer)
    x = get_cp_variable(optimizer, moiconstraint.args[1])
    
    @assert 0 in x.domain "Infeasible problem"
    assign!(x, 0)
    nothing
end

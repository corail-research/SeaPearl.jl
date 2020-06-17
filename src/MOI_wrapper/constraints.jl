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

"""
    MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::MOI.GreaterThan)

Interface function which add a constraint to the model (which is himself an Optimizer).
This constraints a single variable to be greater than a given Integer.  
"""
function MOI.add_constraint(model::Optimizer, sgvar::MOI.SingleVariable, set::MOI.GreaterThan{Float64})
    # get the VariableIndex and convert it to string
    id = sgvar.variable.value
    if isnothing(model.moimodel.variables[id].min) || model.moimodel.variables[id].min <= set.lower
        model.moimodel.variables[id].min = set.lower
    end
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{Float64}}(1)
end

# """
#     MOI.add_constraint(model::Optimizer, sgvar::MOI.ScalarAffineFunction, set::MOI.LessThan)

# Interface function which add a constraint to the model (which is himself an Optimizer).
# This constraints a scalar affine function to be less than a given Integer.  
# """
function term_to_variables(coeff::Float64, variableId::String, opt::Optimizer)
    if coeff == 1
        return AbstractIntVar[]
    end
    if coeff < 0
        new_id = string()
    end
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

# """
#     MOI.add_constraint(model::Optimizer, sgvar::MOI.ScalarAffineFunction, set::MOI.GreaterThan)

# Interface function which add a constraint to the model (which is himself an Optimizer).
# This constraints a scalar affine function to be greater than a given Integer.  
# """
# function MOI.add_constraint(model::Optimizer, saf::MOI.ScalarAffineFunction, set::MOI.GreaterThan)
#     # get the VariableIndexs, convert them to strings and create 
#     var_array = IntVarViewMul[]
#     for term in saf.terms
#         id = term.variable_index.value
#         new_id = string(length(keys(model.cpmodel.variables)) + 1)
#         newvariable = IntVarViewMul(model.cpmodel.variables[id], term.coefficient, new_id)
#         CPRL.addVariable!(model.cpmodel, newvariable)
#         push!(var_array, newvariable)
#     end

#     # create the constraint
#     constraint = SumGreaterThan(var_array, set.lower - saf.constant, model.cpmodel.trailer)

#     # add constraint to the model
#     push!(model.cpmodel.constraints, constraint)

#     # return the constraint Index (asked by MathOptInterface)
#     constraint_index = length(model.cpmodel.constraints) + 1
#     return MOI.ConstraintIndex{MOI.ScalarAffineFunction, MOI.GreaterThan}(constraint_index)
# end


# add_constraint() = @info "Constraint added !"

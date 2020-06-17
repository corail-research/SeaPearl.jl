function fill_cpmodel!(optimizer::Optimizer)
    # Adding variables
    bridge_variables!(optimizer)

    # Adding affine functions
    bridge_affines!(optimizer)

    # Adding constraints
    bridge_constraints!(optimizer)
    

    optimizer
end

function get_cp_variable(optimizer::Optimizer, index::MOI.VariableIndex)
    cp_identifier = optimizer.moimodel.variables[index.value].cp_identifier
    return optimizer.cpmodel.variables[cp_identifier]
end

function get_cp_variable(optimizer::Optimizer, index::AffineIndex)
    cp_identifier = optimizer.moimodel.affines[index.value].cp_identifier
    return optimizer.cpmodel.variables[cp_identifier]
end

function bridge_constraints!(optimizer::Optimizer)
    for moiconstraint in optimizer.moimodel.constraints
        constraint = create_CPConstraint(moiconstraint, optimizer)

        # add constraint to the model
        push!(optimizer.cpmodel.constraints, constraint)
    end
end

function bridge_variables!(optimizer::Optimizer)
    i = 1
    for x in optimizer.moimodel.variables
        @assert !isnothing(x.min) "Every variable must have a lower bound"
        @assert !isnothing(x.max) "Every variable must have an upper bound"
        x.cp_identifier = string(length(keys(optimizer.cpmodel.variables)) + 1)
        newvariable = CPRL.IntVar(x.min, x.max, x.cp_identifier, optimizer.cpmodel.trailer)
        CPRL.addVariable!(optimizer.cpmodel, newvariable)
        i += 1
    end
end

function build_affine_term!(optimizer::Optimizer, vi::MOI.VariableIndex, coeff::Float64)
    @assert isinteger(coeff) "You can't give a float coefficient."

    intCoeff = convert(Int, coeff)

    @assert intCoeff != 0 "Coefficient cannot be null."

    if intCoeff == 1
        return optimizer.cpmodel.variables[optimizer.moimodel.variables[vi.value].cp_identifier]
    end

    if intCoeff < 0
        x = build_affine_term!(optimizer, vi, -coeff)
        new_id = string(length(keys(optimizer.cpmodel.variables)) + 1)
        new_var = IntVarViewOpposite(x, new_id)
        addVariable!(optimizer.cpmodel, new_var)
        return new_var
    end

    x = build_affine_term!(optimizer, vi, 1.)
    new_id = string(length(keys(optimizer.cpmodel.variables)) + 1)
    new_var = IntVarViewMul(x, intCoeff, new_id)
    return new_var
end

function build_affine!(optimizer::Optimizer, aff_function::MOIAffineFunction)
    if !isnothing(aff_function.cp_identifier)
        return aff_function.cp_identifier
    end

    vars = Vector{AbstractIntVar}(undef, length(aff_function.content.terms) + 1)
    for i in 1:length(aff_function.content.terms)
        vi = aff_function.content.terms[i].variable_index
        coeff = aff_function.content.terms[i].coefficient
        x = build_affine_term!(optimizer, vi, coeff)
        vars[i] = x
    end

    # Dealing with the constant
    c = aff_function.content.constant
    c = convert(Int, c)
    if c != 0
        x = vars[length(aff_function.content.terms)]
        new_id = string(length(keys(optimizer.cpmodel.variables)) + 1)
        new_var = IntVarViewOffset(x, c, new_id)
        addVariable!(optimizer.cpmodel, new_var)
        vars[length(aff_function.content.terms)] = new_var
    end

    # Creating the variable that will be equal to the affine function
    minSum, maxSum = 0, 0
    for i in 1:length(aff_function.content.terms)
        minSum += minimum(vars[i].domain)
        maxSum += maximum(vars[i].domain)
    end
    new_id = string(length(keys(optimizer.cpmodel.variables)) + 1)
    sum = IntVar(minSum, maxSum, new_id, optimizer.cpmodel.trailer)
    addVariable!(optimizer.cpmodel, sum)

    # Creating the constraint that will make it equal
    new_id = string(length(keys(optimizer.cpmodel.variables)) + 1)
    lastForSumToZero = IntVarViewOpposite(sum, new_id)
    addVariable!(optimizer.cpmodel, lastForSumToZero)
    vars[end] = lastForSumToZero
    constraint = SumToZero(vars, optimizer.cpmodel.trailer)
    push!(optimizer.cpmodel.constraints, constraint)


    # Returning the CP identifier of the variable that is equal to the affine function (and storing it, a bit ugly)
    aff_function.cp_identifier = sum.id
    sum.id
end

function bridge_affines!(optimizer::Optimizer)
    for aff in optimizer.moimodel.affines
        build_affine!(optimizer, aff)
    end
end

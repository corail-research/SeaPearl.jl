struct CPModel
    variables       ::Array{IntVar}
    constraints     ::Array{Constraint}
    CPModel() = new(IntVar[], Constraint[])
end
@testset "homemade_bridging.jl" begin
    @testset "get_cp_variable(::VariableIndex)" begin
        opt = CPRL.Optimizer()

        x = CPRL.IntVar(1, 2, "x", opt.cpmodel.trailer)
        CPRL.addVariable!(opt.cpmodel, x)

        push!(opt.moimodel.variables, CPRL.MOIVariable("x", 1, 2, MOI.VariableIndex(1)))

        @test CPRL.get_cp_variable(opt, MOI.VariableIndex(1)) == x
    end
    @testset "get_cp_variable(::AffineIndex)" begin
        opt = CPRL.Optimizer()

        x = CPRL.IntVar(1, 2, "x", opt.cpmodel.trailer)
        y = CPRL.IntVar(1, 2, "y", opt.cpmodel.trailer)
        CPRL.addVariable!(opt.cpmodel, x)
        CPRL.addVariable!(opt.cpmodel, y)

        push!(opt.moimodel.variables, CPRL.MOIVariable("x", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, CPRL.MOIVariable("y", 1, 2, MOI.VariableIndex(2)))

        aff = CPRL.MOIAffineFunction("aff", MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([5, -3], [MOI.VariableIndex(1), MOI.VariableIndex(2)]), 3))
        push!(opt.moimodel.affines, aff)

        # Dummy variable
        cp_aff = CPRL.IntVar(1, 2, "aff", opt.cpmodel.trailer) 
        CPRL.addVariable!(opt.cpmodel, cp_aff)


        @test CPRL.get_cp_variable(opt, CPRL.AffineIndex(1)) == cp_aff
    end
    @testset "bridge_constraints!()" begin
        opt = CPRL.Optimizer()

        x = CPRL.IntVar(1, 2, "x", opt.cpmodel.trailer)
        y = CPRL.IntVar(1, 2, "y", opt.cpmodel.trailer)
        z = CPRL.IntVar(1, 2, "z", opt.cpmodel.trailer)
        CPRL.addVariable!(opt.cpmodel, x)
        CPRL.addVariable!(opt.cpmodel, y)
        CPRL.addVariable!(opt.cpmodel, z)
        push!(opt.moimodel.variables, CPRL.MOIVariable("x", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, CPRL.MOIVariable("y", 1, 2, MOI.VariableIndex(2)))
        push!(opt.moimodel.variables, CPRL.MOIVariable("z", 1, 2, MOI.VariableIndex(3)))

        ci1 = MOI.add_constraint(opt, MOI.VectorOfVariables([MOI.VariableIndex(1), MOI.VariableIndex(2)]), CPRL.NotEqualSet())
        ci2 = MOI.add_constraint(opt, MOI.VectorOfVariables([MOI.VariableIndex(3), MOI.VariableIndex(2)]), CPRL.NotEqualSet())

        CPRL.bridge_constraints!(opt)

        @test length(opt.cpmodel.constraints) == 2
        @test isa(opt.cpmodel.constraints[1], CPRL.NotEqual)
        @test CPRL.variablesArray(opt.cpmodel.constraints[1]) == [x, y]
        @test isa(opt.cpmodel.constraints[2], CPRL.NotEqual)
        @test CPRL.variablesArray(opt.cpmodel.constraints[2]) == [z, y]
    end
    @testset "bridge_variables!()" begin
        opt = CPRL.Optimizer()

        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(2)))

        CPRL.bridge_variables!(opt)

        @test length(keys(opt.cpmodel.variables)) == 2
        @test isa(opt.cpmodel.variables["1"], CPRL.IntVar)
        @test isa(opt.cpmodel.variables["2"], CPRL.IntVar)
        @test length(opt.cpmodel.variables["1"].domain) == 2

        opt = CPRL.Optimizer()

        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, nothing, MOI.VariableIndex(2)))

        @test_throws AssertionError CPRL.bridge_variables!(opt)
    end
    @testset "build_affine_term!()" begin
        opt = CPRL.Optimizer()
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        CPRL.bridge_variables!(opt)
        new_var = CPRL.build_affine_term!(opt, MOI.VariableIndex(1), -5.)

        @test length(keys(opt.cpmodel.variables)) == 3
        @test isa(opt.cpmodel.variables["1"], CPRL.IntVar)
        @test isa(opt.cpmodel.variables["2"], CPRL.IntVarViewMul)
        @test isa(opt.cpmodel.variables["3"], CPRL.IntVarViewOpposite)
        @test opt.cpmodel.variables["3"] == new_var
        @test new_var.x == opt.cpmodel.variables["2"]
        @test opt.cpmodel.variables["2"].a == 5
        @test opt.cpmodel.variables["2"].x == opt.cpmodel.variables["1"]


        opt = CPRL.Optimizer()
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        CPRL.bridge_variables!(opt)
        new_var = CPRL.build_affine_term!(opt, MOI.VariableIndex(1), 5.)

        @test length(keys(opt.cpmodel.variables)) == 2
        @test isa(opt.cpmodel.variables["1"], CPRL.IntVar)
        @test isa(opt.cpmodel.variables["2"], CPRL.IntVarViewMul)
        @test opt.cpmodel.variables["2"] == new_var
        @test new_var.a == 5
        @test opt.cpmodel.variables["2"].x == opt.cpmodel.variables["1"]


        opt = CPRL.Optimizer()
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        CPRL.bridge_variables!(opt)
        new_var = CPRL.build_affine_term!(opt, MOI.VariableIndex(1), -1.)

        @test length(keys(opt.cpmodel.variables)) == 2
        @test isa(opt.cpmodel.variables["1"], CPRL.IntVar)
        @test isa(opt.cpmodel.variables["2"], CPRL.IntVarViewOpposite)
        @test opt.cpmodel.variables["2"] == new_var
        @test opt.cpmodel.variables["2"].x == opt.cpmodel.variables["1"]


        opt = CPRL.Optimizer()
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        CPRL.bridge_variables!(opt)
        new_var = CPRL.build_affine_term!(opt, MOI.VariableIndex(1), 1.)

        @test length(keys(opt.cpmodel.variables)) == 1
        @test isa(opt.cpmodel.variables["1"], CPRL.IntVar)
        @test opt.cpmodel.variables["1"] == new_var

        opt = CPRL.Optimizer()
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        CPRL.bridge_variables!(opt)
        @test_throws AssertionError CPRL.build_affine_term!(opt, MOI.VariableIndex(1), 0.)
        @test_throws AssertionError CPRL.build_affine_term!(opt, MOI.VariableIndex(1), -.2)
    end

    @testset "build_affine!()" begin
        opt = CPRL.Optimizer()
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(2)))
        CPRL.bridge_variables!(opt)
        aff = CPRL.MOIAffineFunction(nothing, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([5., -3.], [MOI.VariableIndex(1), MOI.VariableIndex(2)]), 3.))
        push!(opt.moimodel.affines, aff)


        @test CPRL.build_affine!(opt, aff) == "7"
        @test CPRL.get_cp_variable(opt, CPRL.AffineIndex(1)) == opt.cpmodel.variables["7"]

        @test length(keys(opt.cpmodel.variables)) == 8
        @test isa(opt.cpmodel.variables["1"], CPRL.IntVar)
        @test isa(opt.cpmodel.variables["2"], CPRL.IntVar)

        @test isa(opt.cpmodel.variables["3"], CPRL.IntVarViewMul)
        @test opt.cpmodel.variables["3"].a == 5
        @test opt.cpmodel.variables["3"].x == opt.cpmodel.variables["1"]

        @test isa(opt.cpmodel.variables["4"], CPRL.IntVarViewMul)
        @test opt.cpmodel.variables["4"].a == 3
        @test opt.cpmodel.variables["4"].x == opt.cpmodel.variables["2"]

        @test isa(opt.cpmodel.variables["5"], CPRL.IntVarViewOpposite)
        @test opt.cpmodel.variables["5"].x == opt.cpmodel.variables["4"]

        @test isa(opt.cpmodel.variables["6"], CPRL.IntVarViewOffset)
        @test opt.cpmodel.variables["6"].c == 3
        @test opt.cpmodel.variables["6"].x == opt.cpmodel.variables["5"]

        @test isa(opt.cpmodel.variables["7"], CPRL.IntVar)

        @test isa(opt.cpmodel.variables["8"], CPRL.IntVarViewOpposite)
        @test opt.cpmodel.variables["8"].x == opt.cpmodel.variables["7"]

        @test length(opt.cpmodel.constraints) == 1
        @test isa(opt.cpmodel.constraints[1], CPRL.SumToZero)
        @test opt.cpmodel.constraints[1].x == [
            opt.cpmodel.variables["3"],
            opt.cpmodel.variables["6"],
            opt.cpmodel.variables["8"]
        ]
    end

    @testset "bridge_affines!()" begin
        opt = CPRL.Optimizer()
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(2)))
        CPRL.bridge_variables!(opt)
        aff = CPRL.MOIAffineFunction(nothing, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([5., -3.], [MOI.VariableIndex(1), MOI.VariableIndex(2)]), 3.))
        push!(opt.moimodel.affines, aff)

        CPRL.bridge_affines!(opt)
        
        @test CPRL.get_cp_variable(opt, CPRL.AffineIndex(1)) == opt.cpmodel.variables["7"]

        @test length(keys(opt.cpmodel.variables)) == 8
        @test isa(opt.cpmodel.variables["1"], CPRL.IntVar)
        @test isa(opt.cpmodel.variables["2"], CPRL.IntVar)

        @test isa(opt.cpmodel.variables["3"], CPRL.IntVarViewMul)
        @test opt.cpmodel.variables["3"].a == 5
        @test opt.cpmodel.variables["3"].x == opt.cpmodel.variables["1"]

        @test isa(opt.cpmodel.variables["4"], CPRL.IntVarViewMul)
        @test opt.cpmodel.variables["4"].a == 3
        @test opt.cpmodel.variables["4"].x == opt.cpmodel.variables["2"]

        @test isa(opt.cpmodel.variables["5"], CPRL.IntVarViewOpposite)
        @test opt.cpmodel.variables["5"].x == opt.cpmodel.variables["4"]

        @test isa(opt.cpmodel.variables["6"], CPRL.IntVarViewOffset)
        @test opt.cpmodel.variables["6"].c == 3
        @test opt.cpmodel.variables["6"].x == opt.cpmodel.variables["5"]

        @test isa(opt.cpmodel.variables["7"], CPRL.IntVar)

        @test isa(opt.cpmodel.variables["8"], CPRL.IntVarViewOpposite)
        @test opt.cpmodel.variables["8"].x == opt.cpmodel.variables["7"]

        @test length(opt.cpmodel.constraints) == 1
        @test isa(opt.cpmodel.constraints[1], CPRL.SumToZero)
        @test opt.cpmodel.constraints[1].x == [
            opt.cpmodel.variables["3"],
            opt.cpmodel.variables["6"],
            opt.cpmodel.variables["8"]
        ]
    end

    @testset "fill_cpmodel!()" begin
        opt = CPRL.Optimizer()
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(2)))
        aff = CPRL.MOIAffineFunction(nothing, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([5., -3.], [MOI.VariableIndex(1), MOI.VariableIndex(2)]), 3.))
        push!(opt.moimodel.affines, aff)
        
        ci1 = MOI.add_constraint(opt, MOI.VectorOfVariables([MOI.VariableIndex(1), MOI.VariableIndex(2)]), CPRL.NotEqualSet())



        CPRL.fill_cpmodel!(opt)
        
        @test CPRL.get_cp_variable(opt, CPRL.AffineIndex(1)) == opt.cpmodel.variables["7"]

        @test length(keys(opt.cpmodel.variables)) == 8
        @test isa(opt.cpmodel.variables["1"], CPRL.IntVar)
        @test isa(opt.cpmodel.variables["2"], CPRL.IntVar)

        @test isa(opt.cpmodel.variables["3"], CPRL.IntVarViewMul)
        @test opt.cpmodel.variables["3"].a == 5
        @test opt.cpmodel.variables["3"].x == opt.cpmodel.variables["1"]

        @test isa(opt.cpmodel.variables["4"], CPRL.IntVarViewMul)
        @test opt.cpmodel.variables["4"].a == 3
        @test opt.cpmodel.variables["4"].x == opt.cpmodel.variables["2"]

        @test isa(opt.cpmodel.variables["5"], CPRL.IntVarViewOpposite)
        @test opt.cpmodel.variables["5"].x == opt.cpmodel.variables["4"]

        @test isa(opt.cpmodel.variables["6"], CPRL.IntVarViewOffset)
        @test opt.cpmodel.variables["6"].c == 3
        @test opt.cpmodel.variables["6"].x == opt.cpmodel.variables["5"]

        @test isa(opt.cpmodel.variables["7"], CPRL.IntVar)

        @test isa(opt.cpmodel.variables["8"], CPRL.IntVarViewOpposite)
        @test opt.cpmodel.variables["8"].x == opt.cpmodel.variables["7"]

        @test length(opt.cpmodel.constraints) == 2
        @test isa(opt.cpmodel.constraints[2], CPRL.NotEqual)
        @test CPRL.variablesArray(opt.cpmodel.constraints[2]) == [opt.cpmodel.variables["1"], opt.cpmodel.variables["2"]]
        @test isa(opt.cpmodel.constraints[1], CPRL.SumToZero)
        @test opt.cpmodel.constraints[1].x == [
            opt.cpmodel.variables["3"],
            opt.cpmodel.variables["6"],
            opt.cpmodel.variables["8"]
        ]
    end

end
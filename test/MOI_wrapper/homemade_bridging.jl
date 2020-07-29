@testset "homemade_bridging.jl" begin
    @testset "get_cp_variable(::VariableIndex)" begin
        opt = SeaPearl.Optimizer()

        x = SeaPearl.IntVar(1, 2, "x", opt.cpmodel.trailer)
        SeaPearl.addVariable!(opt.cpmodel, x)

        push!(opt.moimodel.variables, SeaPearl.MOIVariable("x", 1, 2, MOI.VariableIndex(1)))

        @test SeaPearl.get_cp_variable(opt, MOI.VariableIndex(1)) == x
    end
    @testset "get_cp_variable(::AffineIndex)" begin
        opt = SeaPearl.Optimizer()

        x = SeaPearl.IntVar(1, 2, "x", opt.cpmodel.trailer)
        y = SeaPearl.IntVar(1, 2, "y", opt.cpmodel.trailer)
        SeaPearl.addVariable!(opt.cpmodel, x)
        SeaPearl.addVariable!(opt.cpmodel, y)

        push!(opt.moimodel.variables, SeaPearl.MOIVariable("x", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("y", 1, 2, MOI.VariableIndex(2)))

        aff = SeaPearl.MOIAffineFunction("aff", MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([5, -3], [MOI.VariableIndex(1), MOI.VariableIndex(2)]), 3))
        push!(opt.moimodel.affines, aff)

        # Dummy variable
        cp_aff = SeaPearl.IntVar(1, 2, "aff", opt.cpmodel.trailer) 
        SeaPearl.addVariable!(opt.cpmodel, cp_aff)


        @test SeaPearl.get_cp_variable(opt, SeaPearl.AffineIndex(1)) == cp_aff
    end
    @testset "bridge_constraints!()" begin
        opt = SeaPearl.Optimizer()

        x = SeaPearl.IntVar(1, 2, "x", opt.cpmodel.trailer)
        y = SeaPearl.IntVar(1, 2, "y", opt.cpmodel.trailer)
        z = SeaPearl.IntVar(1, 2, "z", opt.cpmodel.trailer)
        SeaPearl.addVariable!(opt.cpmodel, x)
        SeaPearl.addVariable!(opt.cpmodel, y)
        SeaPearl.addVariable!(opt.cpmodel, z)
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("x", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("y", 1, 2, MOI.VariableIndex(2)))
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("z", 1, 2, MOI.VariableIndex(3)))

        ci1 = MOI.add_constraint(opt, MOI.VectorOfVariables([MOI.VariableIndex(1), MOI.VariableIndex(2)]), SeaPearl.NotEqualSet())
        ci2 = MOI.add_constraint(opt, MOI.VectorOfVariables([MOI.VariableIndex(3), MOI.VariableIndex(2)]), SeaPearl.NotEqualSet())

        SeaPearl.bridge_constraints!(opt)

        @test length(opt.cpmodel.constraints) == 2
        @test isa(opt.cpmodel.constraints[1], SeaPearl.NotEqual)
        @test SeaPearl.variablesArray(opt.cpmodel.constraints[1]) == [x, y]
        @test isa(opt.cpmodel.constraints[2], SeaPearl.NotEqual)
        @test SeaPearl.variablesArray(opt.cpmodel.constraints[2]) == [z, y]
    end
    @testset "bridge_variables!()" begin
        opt = SeaPearl.Optimizer()

        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(2)))

        SeaPearl.bridge_variables!(opt)

        @test length(keys(opt.cpmodel.variables)) == 2
        @test isa(opt.cpmodel.variables["1"], SeaPearl.IntVar)
        @test isa(opt.cpmodel.variables["2"], SeaPearl.IntVar)
        @test length(opt.cpmodel.variables["1"].domain) == 2

        opt = SeaPearl.Optimizer()

        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, nothing, MOI.VariableIndex(2)))

        @test_throws AssertionError SeaPearl.bridge_variables!(opt)
    end
    @testset "build_affine_term!()" begin
        opt = SeaPearl.Optimizer()
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        SeaPearl.bridge_variables!(opt)
        new_var = SeaPearl.build_affine_term!(opt, MOI.VariableIndex(1), -5.)

        @test length(keys(opt.cpmodel.variables)) == 3
        @test isa(opt.cpmodel.variables["1"], SeaPearl.IntVar)
        @test isa(opt.cpmodel.variables["2"], SeaPearl.IntVarViewMul)
        @test isa(opt.cpmodel.variables["3"], SeaPearl.IntVarViewOpposite)
        @test opt.cpmodel.variables["3"] == new_var
        @test new_var.x == opt.cpmodel.variables["2"]
        @test opt.cpmodel.variables["2"].a == 5
        @test opt.cpmodel.variables["2"].x == opt.cpmodel.variables["1"]


        opt = SeaPearl.Optimizer()
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        SeaPearl.bridge_variables!(opt)
        new_var = SeaPearl.build_affine_term!(opt, MOI.VariableIndex(1), 5.)

        @test length(keys(opt.cpmodel.variables)) == 2
        @test isa(opt.cpmodel.variables["1"], SeaPearl.IntVar)
        @test isa(opt.cpmodel.variables["2"], SeaPearl.IntVarViewMul)
        @test opt.cpmodel.variables["2"] == new_var
        @test new_var.a == 5
        @test opt.cpmodel.variables["2"].x == opt.cpmodel.variables["1"]


        opt = SeaPearl.Optimizer()
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        SeaPearl.bridge_variables!(opt)
        new_var = SeaPearl.build_affine_term!(opt, MOI.VariableIndex(1), -1.)

        @test length(keys(opt.cpmodel.variables)) == 2
        @test isa(opt.cpmodel.variables["1"], SeaPearl.IntVar)
        @test isa(opt.cpmodel.variables["2"], SeaPearl.IntVarViewOpposite)
        @test opt.cpmodel.variables["2"] == new_var
        @test opt.cpmodel.variables["2"].x == opt.cpmodel.variables["1"]


        opt = SeaPearl.Optimizer()
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        SeaPearl.bridge_variables!(opt)
        new_var = SeaPearl.build_affine_term!(opt, MOI.VariableIndex(1), 1.)

        @test length(keys(opt.cpmodel.variables)) == 1
        @test isa(opt.cpmodel.variables["1"], SeaPearl.IntVar)
        @test opt.cpmodel.variables["1"] == new_var

        opt = SeaPearl.Optimizer()
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        SeaPearl.bridge_variables!(opt)
        @test_throws AssertionError SeaPearl.build_affine_term!(opt, MOI.VariableIndex(1), 0.)
        @test_throws AssertionError SeaPearl.build_affine_term!(opt, MOI.VariableIndex(1), -.2)
    end

    @testset "build_affine!()" begin
        opt = SeaPearl.Optimizer()
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(2)))
        SeaPearl.bridge_variables!(opt)
        aff = SeaPearl.MOIAffineFunction(nothing, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([5., -3.], [MOI.VariableIndex(1), MOI.VariableIndex(2)]), 3.))
        push!(opt.moimodel.affines, aff)


        @test SeaPearl.build_affine!(opt, aff) == "7"
        @test SeaPearl.get_cp_variable(opt, SeaPearl.AffineIndex(1)) == opt.cpmodel.variables["7"]

        @test length(keys(opt.cpmodel.variables)) == 8
        @test isa(opt.cpmodel.variables["1"], SeaPearl.IntVar)
        @test isa(opt.cpmodel.variables["2"], SeaPearl.IntVar)

        @test isa(opt.cpmodel.variables["3"], SeaPearl.IntVarViewMul)
        @test opt.cpmodel.variables["3"].a == 5
        @test opt.cpmodel.variables["3"].x == opt.cpmodel.variables["1"]

        @test isa(opt.cpmodel.variables["4"], SeaPearl.IntVarViewMul)
        @test opt.cpmodel.variables["4"].a == 3
        @test opt.cpmodel.variables["4"].x == opt.cpmodel.variables["2"]

        @test isa(opt.cpmodel.variables["5"], SeaPearl.IntVarViewOpposite)
        @test opt.cpmodel.variables["5"].x == opt.cpmodel.variables["4"]

        @test isa(opt.cpmodel.variables["6"], SeaPearl.IntVarViewOffset)
        @test opt.cpmodel.variables["6"].c == 3
        @test opt.cpmodel.variables["6"].x == opt.cpmodel.variables["5"]

        @test isa(opt.cpmodel.variables["7"], SeaPearl.IntVar)

        @test isa(opt.cpmodel.variables["8"], SeaPearl.IntVarViewOpposite)
        @test opt.cpmodel.variables["8"].x == opt.cpmodel.variables["7"]

        @test length(opt.cpmodel.constraints) == 1
        @test isa(opt.cpmodel.constraints[1], SeaPearl.SumToZero)
        @test opt.cpmodel.constraints[1].x == [
            opt.cpmodel.variables["3"],
            opt.cpmodel.variables["6"],
            opt.cpmodel.variables["8"]
        ]
    end

    @testset "bridge_affines!()" begin
        opt = SeaPearl.Optimizer()
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(2)))
        SeaPearl.bridge_variables!(opt)
        aff = SeaPearl.MOIAffineFunction(nothing, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([5., -3.], [MOI.VariableIndex(1), MOI.VariableIndex(2)]), 3.))
        push!(opt.moimodel.affines, aff)

        SeaPearl.bridge_affines!(opt)
        
        @test SeaPearl.get_cp_variable(opt, SeaPearl.AffineIndex(1)) == opt.cpmodel.variables["7"]

        @test length(keys(opt.cpmodel.variables)) == 8
        @test isa(opt.cpmodel.variables["1"], SeaPearl.IntVar)
        @test isa(opt.cpmodel.variables["2"], SeaPearl.IntVar)

        @test isa(opt.cpmodel.variables["3"], SeaPearl.IntVarViewMul)
        @test opt.cpmodel.variables["3"].a == 5
        @test opt.cpmodel.variables["3"].x == opt.cpmodel.variables["1"]

        @test isa(opt.cpmodel.variables["4"], SeaPearl.IntVarViewMul)
        @test opt.cpmodel.variables["4"].a == 3
        @test opt.cpmodel.variables["4"].x == opt.cpmodel.variables["2"]

        @test isa(opt.cpmodel.variables["5"], SeaPearl.IntVarViewOpposite)
        @test opt.cpmodel.variables["5"].x == opt.cpmodel.variables["4"]

        @test isa(opt.cpmodel.variables["6"], SeaPearl.IntVarViewOffset)
        @test opt.cpmodel.variables["6"].c == 3
        @test opt.cpmodel.variables["6"].x == opt.cpmodel.variables["5"]

        @test isa(opt.cpmodel.variables["7"], SeaPearl.IntVar)

        @test isa(opt.cpmodel.variables["8"], SeaPearl.IntVarViewOpposite)
        @test opt.cpmodel.variables["8"].x == opt.cpmodel.variables["7"]

        @test length(opt.cpmodel.constraints) == 1
        @test isa(opt.cpmodel.constraints[1], SeaPearl.SumToZero)
        @test opt.cpmodel.constraints[1].x == [
            opt.cpmodel.variables["3"],
            opt.cpmodel.variables["6"],
            opt.cpmodel.variables["8"]
        ]
    end

    @testset "fill_cpmodel!()" begin
        opt = SeaPearl.Optimizer()
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(2)))
        aff = SeaPearl.MOIAffineFunction(nothing, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([5., -3.], [MOI.VariableIndex(1), MOI.VariableIndex(2)]), 3.))
        push!(opt.moimodel.affines, aff)
        
        ci1 = MOI.add_constraint(opt, MOI.VectorOfVariables([MOI.VariableIndex(1), MOI.VariableIndex(2)]), SeaPearl.NotEqualSet())



        SeaPearl.fill_cpmodel!(opt)
        
        @test SeaPearl.get_cp_variable(opt, SeaPearl.AffineIndex(1)) == opt.cpmodel.variables["7"]

        @test length(keys(opt.cpmodel.variables)) == 8
        @test isa(opt.cpmodel.variables["1"], SeaPearl.IntVar)
        @test isa(opt.cpmodel.variables["2"], SeaPearl.IntVar)

        @test isa(opt.cpmodel.variables["3"], SeaPearl.IntVarViewMul)
        @test opt.cpmodel.variables["3"].a == 5
        @test opt.cpmodel.variables["3"].x == opt.cpmodel.variables["1"]

        @test isa(opt.cpmodel.variables["4"], SeaPearl.IntVarViewMul)
        @test opt.cpmodel.variables["4"].a == 3
        @test opt.cpmodel.variables["4"].x == opt.cpmodel.variables["2"]

        @test isa(opt.cpmodel.variables["5"], SeaPearl.IntVarViewOpposite)
        @test opt.cpmodel.variables["5"].x == opt.cpmodel.variables["4"]

        @test isa(opt.cpmodel.variables["6"], SeaPearl.IntVarViewOffset)
        @test opt.cpmodel.variables["6"].c == 3
        @test opt.cpmodel.variables["6"].x == opt.cpmodel.variables["5"]

        @test isa(opt.cpmodel.variables["7"], SeaPearl.IntVar)

        @test isa(opt.cpmodel.variables["8"], SeaPearl.IntVarViewOpposite)
        @test opt.cpmodel.variables["8"].x == opt.cpmodel.variables["7"]

        @test length(opt.cpmodel.constraints) == 2
        @test isa(opt.cpmodel.constraints[2], SeaPearl.NotEqual)
        @test SeaPearl.variablesArray(opt.cpmodel.constraints[2]) == [opt.cpmodel.variables["1"], opt.cpmodel.variables["2"]]
        @test isa(opt.cpmodel.constraints[1], SeaPearl.SumToZero)
        @test opt.cpmodel.constraints[1].x == [
            opt.cpmodel.variables["3"],
            opt.cpmodel.variables["6"],
            opt.cpmodel.variables["8"]
        ]
    end

end
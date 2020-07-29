@testset "constraints.jl" begin
    @testset "MOI.add_constraint(::NotEqualSet)" begin
        opt = SeaPearl.Optimizer()

        x = MOI.add_variable(opt)
        y = MOI.add_variable(opt)

        ci = MOI.add_constraint(opt, MOI.VectorOfVariables([x, y]), SeaPearl.NotEqualSet())
        @test ci == MOI.ConstraintIndex{MOI.VectorOfVariables, SeaPearl.NotEqualSet}(1)
        @test length(opt.moimodel.constraints) == 1
        @test opt.moimodel.constraints[1] == SeaPearl.MOIConstraint(SeaPearl.NotEqualSet, (x, y), ci)
    end
    @testset "create_CPConstraint(::NotEqualSet)" begin
        opt = SeaPearl.Optimizer()

        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(1)))
        push!(opt.moimodel.variables, SeaPearl.MOIVariable("", 1, 2, MOI.VariableIndex(2)))
        x = MOI.VariableIndex(1)
        y = MOI.VariableIndex(2)

        ci = MOI.add_constraint(opt, MOI.VectorOfVariables([x, y]), SeaPearl.NotEqualSet())

        SeaPearl.bridge_variables!(opt)

        cp_constraint = SeaPearl.create_CPConstraint(opt.moimodel.constraints[1], opt)
        @test isa(cp_constraint, SeaPearl.NotEqual)
        @test SeaPearl.variablesArray(cp_constraint) == [SeaPearl.get_cp_variable(opt, x), SeaPearl.get_cp_variable(opt, y)]
    end
    @testset "MOI.add_constraint(::LessThan)" begin
        opt = SeaPearl.Optimizer()

        x = MOI.add_variable(opt)

        set = MOI.LessThan(5.)
        ci = MOI.add_constraint(opt, x, set)
        @test opt.moimodel.variables[1].max == 5
        @test isnothing(opt.moimodel.variables[1].min)
    end
    @testset "MOI.add_constraint(::GreaterThan)" begin
        opt = SeaPearl.Optimizer()

        x = MOI.add_variable(opt)

        set = MOI.GreaterThan(5.)
        ci = MOI.add_constraint(opt, x, set)
        @test opt.moimodel.variables[1].min == 5
        @test isnothing(opt.moimodel.variables[1].max)
    end
    @testset "MOI.add_constraint(::MOI.ScalarAffineFunction, ::MOI.EqualTo)" begin
        opt = SeaPearl.Optimizer()

        x = MOI.add_variable(opt)
        y = MOI.add_variable(opt)
        aff = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([5., -3.], [x, y]), 3.)

        ci = MOI.add_constraint(opt, aff, MOI.EqualTo(5.))
        @test aff.constant == -2
        @test length(opt.moimodel.constraints) == 1
        @test opt.moimodel.constraints[1] == SeaPearl.MOIConstraint(MOI.EqualTo, (SeaPearl.AffineIndex(1),), ci)
        @test length(opt.moimodel.affines) == 1
        @test opt.moimodel.affines[1].content == aff
        @test isnothing(opt.moimodel.affines[1].cp_identifier)
    end
    @testset "create_CPConstraint(::MOI.EqualTo)" begin
        opt = SeaPearl.Optimizer()

        x = MOI.add_variable(opt)
        MOI.add_constraint(opt, x, MOI.LessThan(2.))
        MOI.add_constraint(opt, x, MOI.GreaterThan(1.))
        y = MOI.add_variable(opt)
        MOI.add_constraint(opt, y, MOI.LessThan(5.))
        MOI.add_constraint(opt, y, MOI.GreaterThan(0.))
        aff = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([5., -3.], [x, y]), 3.)

        ci = MOI.add_constraint(opt, aff, MOI.EqualTo(5.))

        SeaPearl.bridge_variables!(opt)
        SeaPearl.bridge_affines!(opt)

        cp_constraint = SeaPearl.create_CPConstraint(opt.moimodel.constraints[1], opt)

        @test SeaPearl.assignedValue(opt.cpmodel.variables["7"]) == 0

        # Sometimes clearly infeasible
        opt = SeaPearl.Optimizer()

        x = MOI.add_variable(opt)
        MOI.add_constraint(opt, x, MOI.LessThan(2.))
        MOI.add_constraint(opt, x, MOI.GreaterThan(1.))
        y = MOI.add_variable(opt)
        MOI.add_constraint(opt, y, MOI.LessThan(5.))
        MOI.add_constraint(opt, y, MOI.GreaterThan(4.))
        aff = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([5., -3.], [x, y]), 3.)

        ci = MOI.add_constraint(opt, aff, MOI.EqualTo(5.))

        SeaPearl.bridge_variables!(opt)
        SeaPearl.bridge_affines!(opt)

        @test_throws AssertionError SeaPearl.create_CPConstraint(opt.moimodel.constraints[1], opt)
    end
end
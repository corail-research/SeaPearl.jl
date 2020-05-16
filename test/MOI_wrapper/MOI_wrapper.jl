@testset "MOI_wrapper.jl" begin

    @testset "Adding variables" begin
        model = CPRL.Optimizer()
        CPRL.MOI.add_variable(model)
        @test "1" in keys(model.cpmodel.variables)
        @test !("2" in keys(model.cpmodel.variables))
    end

    @testset "add_constraint()" begin
        @test CPRL.add_constraint() == nothing
        @test_logs (:info, "Constraint added !") CPRL.add_constraint()
    end
end
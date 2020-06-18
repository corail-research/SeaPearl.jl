@testset "variables.jl" begin
    @testset "MOI.add_variable()" begin
        opt = CPRL.Optimizer()
        push!(opt.moimodel.variables, CPRL.MOIVariable("", 1, 2, MOI.VariableIndex(1)))

        @test MOI.add_variable(opt) == MOI.VariableIndex(2)
        @test length(opt.moimodel.variables) == 2
        @test isnothing(opt.moimodel.variables[2].min)
        @test isnothing(opt.moimodel.variables[2].max)
        @test opt.moimodel.variables[2].vi == MOI.VariableIndex(2)
        @test opt.moimodel.variables[2].cp_identifier == ""
    end
end
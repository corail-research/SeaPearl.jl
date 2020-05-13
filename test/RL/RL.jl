using CPRL.RL

@testset "RL.jl" begin

    @testset "selectValue()" begin
        @test CPRL.RL.selectValue() == 3
    end
end
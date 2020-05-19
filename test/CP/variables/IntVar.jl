@testset "IntVar.jl" begin
    @testset "isbound()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)

        @test !CPRL.isbound(x)

        CPRL.assign!(x, 3)

        @test CPRL.isbound(x)
    end

    @testset "assignedValue()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 5, "x", trailer)

        @test CPRL.assignedValue(x) == 5

        y = CPRL.IntVar(5, 8, "y", trailer)
        @test_throws AssertionError CPRL.assignedValue(y)
    end


    @testset "IntVar()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 8, "x", trailer)

        @test length(x.domain) == 4
        @test 5 in x.domain && 8 in x.domain && !(4 in x.domain) && !(9 in x.domain)
    end
end
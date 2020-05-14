using Test
using CPRL
@testset "variables.jl" begin
    @testset "isempty()" begin
        trailer = CPRL.Trailer()
        domNotEmpty = CPRL.IntDomain(trailer, 20, 10)

        @test !isempty(domNotEmpty)

        emptyDom = CPRL.IntDomain(trailer, 0, 1)
        @test isempty(emptyDom)
    end

    @testset "length()" begin
        trailer = CPRL.Trailer()
        dom20 = CPRL.IntDomain(trailer, 20, 10)
        @test length(dom20) == 20

        dom2 = CPRL.IntDomain(trailer, 2, 0)

        @test length(dom2) == 2
    end

    @testset "in()" begin
        trailer = CPRL.Trailer()
        dom20 = CPRL.IntDomain(trailer, 20, 10)

        @test 11 in dom20
        @test !(10 in dom20)
        @test 21 in dom20
        @test !(1 in dom20)
        @test !(30 in dom20)
    end
end
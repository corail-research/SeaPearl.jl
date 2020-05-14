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

    @testset "exchangePositions!()" begin
        trailer = CPRL.Trailer()
        dom = CPRL.IntDomain(trailer, 5, 10)

        @test dom.values == [1, 2, 3, 4, 5]
        @test dom.indexes == [1, 2, 3, 4, 5]

        CPRL.exchangePositions!(dom, 2, 5)

        @test dom.values == [1, 5, 3, 4, 2]
        @test dom.indexes == [1, 5, 3, 4, 2]
    end

    @testset "remove!()" begin
        trailer = CPRL.Trailer()
        dom = CPRL.IntDomain(trailer, 5, 10)

        CPRL.remove!(dom, 11)


        @test !(11 in dom)
        @test length(dom) == 4
    end
end
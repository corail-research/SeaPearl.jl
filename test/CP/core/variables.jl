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
        @test !(31 in dom20)
    end

    @testset "exchangePositions!()" begin
        trailer = CPRL.Trailer()
        dom = CPRL.IntDomain(trailer, 5, 10)

        @test dom.values == [1, 2, 3, 4, 5]
        @test dom.indexes == [1, 2, 3, 4, 5]

        CPRL.exchangePositions!(dom, 2, 5)

        @test dom.values == [1, 5, 3, 4, 2]
        @test dom.indexes == [1, 5, 3, 4, 2]

        CPRL.exchangePositions!(dom, 2, 1)

        @test dom.values == [2, 5, 3, 4, 1]
        @test dom.indexes == [5, 1, 3, 4, 2]
    end

    @testset "remove!()" begin
        trailer = CPRL.Trailer()
        dom = CPRL.IntDomain(trailer, 5, 10)

        CPRL.remove!(dom, 11)


        @test !(11 in dom)
        @test length(dom) == 4
        @test dom.min.value == 12
    end

    @testset "assign!()" begin
        trailer = CPRL.Trailer()
        dom = CPRL.IntDomain(trailer, 5, 10)

        removed = CPRL.assign!(dom, 14)

        @test !(12 in dom)
        @test 14 in dom
        @test length(dom) == 1
        @test sort(removed) == [11, 12, 13, 15]
        @test dom.max.value == 14 && dom.min.value == 14
    end

    @testset "iterate()" begin
        trailer = CPRL.Trailer()
        dom = CPRL.IntDomain(trailer, 3, 10)

        j = 11
        for i in dom
            @test j == i
            j += 1
        end

        @test j == 14

    end

    @testset "removeAll!()" begin
        trailer = CPRL.Trailer()
        dom = CPRL.IntDomain(trailer, 3, 10)

        removed = CPRL.removeAll!(dom)

        @test isempty(dom)
        @test removed == [11, 12, 13]
    end

    @testset "isbound()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)

        @test !CPRL.isbound(x)

        CPRL.assign!(x, 3)

        @test CPRL.isbound(x)
    end

    @testset "IntVar()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 8, "x", trailer)

        @test length(x.domain) == 4
        @test 5 in x.domain && 8 in x.domain && !(4 in x.domain) && !(9 in x.domain)
    end

    @testset "assignedValue()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 5, "x", trailer)

        @test CPRL.assignedValue(x) == 5

        y = CPRL.IntVar(5, 8, "y", trailer)
        @test_throws AssertionError CPRL.assignedValue(y)
    end

    @testset "updateMinFromRemovedVal!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 10, "x", trailer)

        @test x.domain.min.value == 5

        CPRL.remove!(x.domain, 5)
        CPRL.updateMinFromRemovedVal!(x.domain, 5)

        @test x.domain.min.value == 6
    end

    @testset "updateMaxFromRemovedVal!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 10, "x", trailer)

        @test x.domain.max.value == 10

        CPRL.remove!(x.domain, 10)
        CPRL.updateMaxFromRemovedVal!(x.domain, 10)

        @test x.domain.max.value == 9
    end

    @testset "updateBoundsFromRemovedVal!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 10, "x", trailer)

        CPRL.remove!(x.domain, 5)
        CPRL.remove!(x.domain, 10)
        CPRL.updateBoundsFromRemovedVal!(x.domain, 5)
        CPRL.updateBoundsFromRemovedVal!(x.domain, 10)

        @test x.domain.min.value == 6
        @test x.domain.max.value == 9
    end

    @testset "removeAbove!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 10, "x", trailer)

        CPRL.removeAbove!(x.domain, 7)

        @test length(x.domain) == 3
        @test 7 in x.domain
        @test 6 in x.domain
        @test !(8 in x.domain)

        CPRL.removeAbove!(x.domain, 4)

        @test isempty(x.domain)
    end

    @testset "removeBelow!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 10, "x", trailer)

        CPRL.removeBelow!(x.domain, 7)

        @test length(x.domain) == 4
        @test 7 in x.domain
        @test 8 in x.domain
        @test !(6 in x.domain)

        CPRL.removeBelow!(x.domain, 11)

        @test isempty(x.domain)
    end
end
@testset "IntDomain.jl" begin
    @testset "isempty()" begin
        trailer = SeaPearl.Trailer()
        domNotEmpty = SeaPearl.IntDomain(trailer, 20, 10)

        @test !isempty(domNotEmpty)

        emptyDom = SeaPearl.IntDomain(trailer, 0, 1)
        @test isempty(emptyDom)
    end

    @testset "length()" begin
        trailer = SeaPearl.Trailer()
        dom20 = SeaPearl.IntDomain(trailer, 20, 10)
        @test length(dom20) == 20

        dom2 = SeaPearl.IntDomain(trailer, 2, 0)

        @test length(dom2) == 2
    end

    @testset "in()" begin
        trailer = SeaPearl.Trailer()
        dom20 = SeaPearl.IntDomain(trailer, 20, 10)

        @test 11 in dom20
        @test !(10 in dom20)
        @test 21 in dom20
        @test !(1 in dom20)
        @test !(31 in dom20)
    end

    @testset "exchangePositions!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntDomain(trailer, 5, 10)

        @test dom.values == [1, 2, 3, 4, 5]
        @test dom.indexes == [1, 2, 3, 4, 5]

        SeaPearl.exchangePositions!(dom, 2, 5)

        @test dom.values == [1, 5, 3, 4, 2]
        @test dom.indexes == [1, 5, 3, 4, 2]

        SeaPearl.exchangePositions!(dom, 2, 1)

        @test dom.values == [2, 5, 3, 4, 1]
        @test dom.indexes == [5, 1, 3, 4, 2]
    end

    @testset "remove!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntDomain(trailer, 5, 10)

        SeaPearl.remove!(dom, 11)


        @test !(11 in dom)
        @test length(dom) == 4
        @test dom.min.value == 12
    end

    @testset "assign!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntDomain(trailer, 5, 10)

        removed = SeaPearl.assign!(dom, 14)

        @test !(12 in dom)
        @test 14 in dom
        @test length(dom) == 1
        @test sort(removed) == [11, 12, 13, 15]
        @test dom.max.value == 14 && dom.min.value == 14
    end

    @testset "iterate()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntDomain(trailer, 3, 10)

        j = 11
        for i in dom
            @test j == i
            j += 1
        end

        @test j == 14

    end

    @testset "removeAll!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntDomain(trailer, 3, 10)

        removed = SeaPearl.removeAll!(dom)

        @test isempty(dom)
        @test removed == [11, 12, 13]
    end

    @testset "updateMinFromRemovedVal!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 10, "x", trailer)

        @test minimum(x.domain) == 5

        SeaPearl.remove!(x.domain, 5)
        SeaPearl.updateMinFromRemovedVal!(x.domain, 5)

        @test minimum(x.domain) == 6
    end

    @testset "updateMaxFromRemovedVal!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 10, "x", trailer)

        @test maximum(x.domain) == 10

        SeaPearl.remove!(x.domain, 10)
        SeaPearl.updateMaxFromRemovedVal!(x.domain, 10)

        @test maximum(x.domain) == 9
    end

    @testset "updateBoundsFromRemovedVal!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 10, "x", trailer)

        SeaPearl.remove!(x.domain, 5)
        SeaPearl.remove!(x.domain, 10)
        SeaPearl.updateBoundsFromRemovedVal!(x.domain, 5)
        SeaPearl.updateBoundsFromRemovedVal!(x.domain, 10)

        @test minimum(x.domain) == 6
        @test maximum(x.domain) == 9
    end

    @testset "removeAbove!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 10, "x", trailer)

        @test sort(SeaPearl.removeAbove!(x.domain, 7)) == [8, 9, 10]

        @test length(x.domain) == 3
        @test 7 in x.domain
        @test 6 in x.domain
        @test !(8 in x.domain)

        @test sort(SeaPearl.removeAbove!(x.domain, 4)) == [5, 6, 7]

        @test isempty(x.domain)
    end

    @testset "removeBelow!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 10, "x", trailer)

        @test sort(SeaPearl.removeBelow!(x.domain, 7)) == [5, 6]

        @test length(x.domain) == 4
        @test 7 in x.domain
        @test 8 in x.domain
        @test !(6 in x.domain)

        @test sort(SeaPearl.removeBelow!(x.domain, 11)) == [7, 8, 9, 10]

        @test isempty(x.domain)
    end

    @testset "minimum()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 10, "x", trailer)

        @test SeaPearl.minimum(x.domain) == 5
    end

    
    @testset "maximum()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 10, "x", trailer)

        @test SeaPearl.maximum(x.domain) == 10
    end

    @testset "reset_domain!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 10, "x", trailer)
        SeaPearl.assign!(x, 10)
        
        @test x.domain.values == [6, 2, 3, 4, 5, 1]
        @test x.domain.indexes == [6, 2, 3, 4, 5, 1]
        @test SeaPearl.length(x.domain) == 1
        SeaPearl.reset_domain!(x.domain)
        @test x.domain.values == [1, 2, 3, 4, 5, 6]
        @test x.domain.indexes == [1, 2, 3, 4, 5, 6]
        @test SeaPearl.length(x.domain) == 6
    end
end
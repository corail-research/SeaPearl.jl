@testset "IntVarViewMul.jl" begin
    
    @testset "isempty()" begin
        trailer = CPRL.Trailer()
        domNotEmpty = CPRL.IntDomain(trailer, 20, 10)
        ax = CPRL.IntDomainViewMul(domNotEmpty, 4)

        @test !isempty(ax)

        emptyDom = CPRL.IntDomain(trailer, 0, 1)
        ay = CPRL.IntDomainViewMul(emptyDom, 4)
        @test isempty(ay)
    end

    @testset "length()" begin
        trailer = CPRL.Trailer()
        dom20 = CPRL.IntDomain(trailer, 20, 10)
        ax = CPRL.IntDomainViewMul(dom20, 4)
        @test length(ax) == 20

        dom2 = CPRL.IntDomain(trailer, 2, 0)
        ax = CPRL.IntDomainViewMul(dom2, 4)

        @test length(ax) == 2
    end

    @testset "in()" begin
        trailer = CPRL.Trailer()
        dom20 = CPRL.IntDomain(trailer, 3, 2)
        ax = CPRL.IntDomainViewMul(dom20, 4)

        @test !(2 in ax)
        @test !(3 in ax)
        @test 12 in ax
        @test !(13 in ax)
        @test 16 in ax
    end

    @testset "minimum()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 10, "x", trailer)
        axDom = CPRL.IntDomainViewMul(x.domain, 4)

        @test CPRL.minimum(axDom) == 20
    end

    @testset "removeAll!()" begin
        trailer = CPRL.Trailer()
        dom = CPRL.IntDomain(trailer, 3, 10)
        axDom = CPRL.IntDomainViewMul(dom, 4)

        removed = CPRL.removeAll!(axDom)

        @test isempty(axDom)
        @test removed == [44, 48, 52]
    end

    
    @testset "maximum()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 10, "x", trailer)
        axDom = CPRL.IntDomainViewMul(x.domain, 4)

        @test CPRL.maximum(axDom) == 40
    end

    @testset "remove!()" begin
        trailer = CPRL.Trailer()
        dom = CPRL.IntDomain(trailer, 3, 2)
        ax = CPRL.IntDomainViewMul(dom, 4)

        CPRL.remove!(ax, 12)


        @test !(12 in ax)
        @test length(ax) == 2
        @test CPRL.minimum(ax) == 16
    end

    @testset "removeAbove!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewMul(x.domain, 4)

        @test sort(CPRL.removeAbove!(axDom, 8)) == [12, 16, 20]

        @test length(axDom) == 2
        @test 8 in axDom
        @test 4 in axDom
        @test !(12 in axDom)

        @test sort(CPRL.removeAbove!(axDom, 2)) == [4, 8]

        @test isempty(axDom)

        
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewMul(x.domain, 4)

        @test sort(CPRL.removeAbove!(axDom, 10)) == [12, 16, 20]
        @test length(axDom) == 2
        @test 8 in axDom
        @test 4 in axDom
        @test !(12 in axDom)
    end

    @testset "removeBelow!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewMul(x.domain, 4)

        @test sort(CPRL.removeBelow!(axDom, 8)) == [4]

        @test length(axDom) == 4
        @test 8 in axDom
        @test 12 in axDom
        @test !(4 in axDom)

        @test sort(CPRL.removeBelow!(axDom, 21)) == [8, 12, 16, 20]

        @test isempty(axDom)

        
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewMul(x.domain, 4)

        @test sort(CPRL.removeBelow!(axDom, 6)) == [4]
        
        @test length(axDom) == 4
        @test 8 in axDom
        @test 12 in axDom
        @test !(4 in axDom)
    end

    @testset "iterate()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewMul(x.domain, 4)

        j = 4
        for i in axDom
            @test j == i
            j += 4
        end

        @test j == 24

    end

    @testset "updateMinFromRemovedVal!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewMul(x.domain, 4)

        @test CPRL.minimum(axDom) == 4

        CPRL.remove!(axDom, 4)
        CPRL.updateMinFromRemovedVal!(axDom, 4)

        @test CPRL.minimum(axDom) == 8
    end

    @testset "updateMaxFromRemovedVal!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewMul(x.domain, 4)

        @test CPRL.maximum(axDom) == 20

        CPRL.remove!(axDom, 20)
        CPRL.updateMinFromRemovedVal!(axDom, 20)

        @test CPRL.maximum(axDom) == 16
    end

    @testset "updateBoundsFromRemovedVal!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewMul(x.domain, 4)

        CPRL.remove!(axDom, 20)
        CPRL.remove!(axDom, 4)
        CPRL.updateBoundsFromRemovedVal!(axDom, 20)
        CPRL.updateBoundsFromRemovedVal!(axDom, 4)

        @test CPRL.minimum(axDom) == 8
        @test CPRL.maximum(axDom) == 16
    end

    @testset "isbound()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        ax = CPRL.IntVarViewMul(x, 3, "ax")

        @test !CPRL.isbound(ax)

        CPRL.assign!(ax, 6)

        @test CPRL.isbound(ax)
    end

    @testset "assignedValue()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 5, "x", trailer)
        ax = CPRL.IntVarViewMul(x, 3, "ax")

        @test CPRL.assignedValue(ax) == 15

        y = CPRL.IntVar(5, 8, "y", trailer)
        ay = CPRL.IntVarViewMul(y, 3, "ay")
        @test_throws AssertionError CPRL.assignedValue(y)
    end
end
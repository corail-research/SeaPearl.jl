@testset "IntVarViewOpposite.jl" begin
    
    @testset "isempty()" begin
        trailer = CPRL.Trailer()
        domNotEmpty = CPRL.IntDomain(trailer, 20, 10)
        ax = CPRL.IntDomainViewOpposite(domNotEmpty)

        @test !isempty(ax)

        emptyDom = CPRL.IntDomain(trailer, 0, 1)
        ay = CPRL.IntDomainViewOpposite(emptyDom)
        @test isempty(ay)
    end

    @testset "length()" begin
        trailer = CPRL.Trailer()
        dom20 = CPRL.IntDomain(trailer, 20, 10)
        ax = CPRL.IntDomainViewOpposite(dom20)
        @test length(ax) == 20

        dom2 = CPRL.IntDomain(trailer, 2, 0)
        ax = CPRL.IntDomainViewOpposite(dom2)

        @test length(ax) == 2
    end

    @testset "in()" begin
        trailer = CPRL.Trailer()
        dom20 = CPRL.IntDomain(trailer, 3, 2)
        ax = CPRL.IntDomainViewOpposite(dom20)

        @test !(4 in ax)
        @test !(3 in ax)
        @test -3 in ax
        @test !(-6 in ax)
        @test -5 in ax
    end

    @testset "minimum()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 10, "x", trailer)
        axDom = CPRL.IntDomainViewOpposite(x.domain)

        @test CPRL.minimum(axDom) == -10
    end

    @testset "removeAll!()" begin
        trailer = CPRL.Trailer()
        dom = CPRL.IntDomain(trailer, 3, 10)
        axDom = CPRL.IntDomainViewOpposite(dom)

        removed = CPRL.removeAll!(axDom)

        @test isempty(axDom)
        @test removed == [-11, -12, -13]
    end

    
    @testset "maximum()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 10, "x", trailer)
        axDom = CPRL.IntDomainViewOpposite(x.domain)

        @test CPRL.maximum(axDom) == -5
    end

    @testset "remove!()" begin
        trailer = CPRL.Trailer()
        dom = CPRL.IntDomain(trailer, 3, 2)
        ax = CPRL.IntDomainViewOpposite(dom)

        CPRL.remove!(ax, -5)


        @test !(-5 in ax)
        @test length(ax) == 2
        @test CPRL.minimum(ax) == -4
    end

    @testset "removeAbove!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewOpposite(x.domain)

        @test sort(CPRL.removeAbove!(axDom, -4)) == [-3, -2, -1]

        @test length(axDom) == 2
        @test -4 in axDom
        @test -5 in axDom
        @test !(-3 in axDom)

        @test sort(CPRL.removeAbove!(axDom, -6)) == [-5, -4]

        @test isempty(axDom)
    end

    @testset "removeBelow!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewOpposite(x.domain)

        @test sort(CPRL.removeBelow!(axDom, -4)) == [-5]

        @test length(axDom) == 4
        @test -4 in axDom
        @test -3 in axDom
        @test !(-5 in axDom)

        @test sort(CPRL.removeBelow!(axDom, 0)) == [-4, -3, -2, -1]

        @test isempty(axDom)
    end

    @testset "iterate()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewOpposite(x.domain)

        j = -1
        for i in axDom
            @test j == i
            j -= 1
        end

        @test j == -6

    end

    @testset "updateMinFromRemovedVal!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewOpposite(x.domain)

        @test CPRL.minimum(axDom) == -5

        CPRL.remove!(axDom, -5)
        CPRL.updateMinFromRemovedVal!(axDom, -5)

        @test CPRL.minimum(axDom) == -4
    end

    @testset "updateMaxFromRemovedVal!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewOpposite(x.domain)

        @test CPRL.maximum(axDom) == -1

        CPRL.remove!(axDom, -1)
        CPRL.updateMaxFromRemovedVal!(axDom, -1)

        @test CPRL.maximum(axDom) == -2
    end

    @testset "updateBoundsFromRemovedVal!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(1, 5, "x", trailer)
        axDom = CPRL.IntDomainViewOpposite(x.domain)

        CPRL.remove!(axDom, -5)
        CPRL.remove!(axDom, -1)
        CPRL.updateBoundsFromRemovedVal!(axDom, -5)
        CPRL.updateBoundsFromRemovedVal!(axDom, -1)

        @test CPRL.minimum(axDom) == -4
        @test CPRL.maximum(axDom) == -2
    end

    @testset "isbound()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        ax = CPRL.IntVarViewOpposite(x, "-x")

        @test !CPRL.isbound(ax)

        CPRL.assign!(ax, -5)

        @test CPRL.isbound(ax)
    end

    @testset "assignedValue()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(5, 5, "x", trailer)
        ax = CPRL.IntVarViewOpposite(x, "-x")

        @test CPRL.assignedValue(ax) == -5

        y = CPRL.IntVar(5, 8, "y", trailer)
        ay = CPRL.IntVarViewOpposite(y, "-y")
        @test_throws AssertionError CPRL.assignedValue(y)
    end
end
@testset "IntVarView.jl" begin
    @testset "IntVarViewMul" begin
        @testset "isempty()" begin
            trailer = SeaPearl.Trailer()
            domNotEmpty = SeaPearl.IntDomain(trailer, 20, 10)
            ax = SeaPearl.IntDomainViewMul(domNotEmpty, 4)

            @test !isempty(ax)

            emptyDom = SeaPearl.IntDomain(trailer, 0, 1)
            ay = SeaPearl.IntDomainViewMul(emptyDom, 4)
            @test isempty(ay)
        end

        @testset "length()" begin
            trailer = SeaPearl.Trailer()
            dom20 = SeaPearl.IntDomain(trailer, 20, 10)
            ax = SeaPearl.IntDomainViewMul(dom20, 4)
            @test length(ax) == 20

            dom2 = SeaPearl.IntDomain(trailer, 2, 0)
            ax = SeaPearl.IntDomainViewMul(dom2, 4)

            @test length(ax) == 2
        end

        @testset "in()" begin
            trailer = SeaPearl.Trailer()
            dom20 = SeaPearl.IntDomain(trailer, 3, 2)
            ax = SeaPearl.IntDomainViewMul(dom20, 4)

            @test !(2 in ax)
            @test !(3 in ax)
            @test 12 in ax
            @test !(13 in ax)
            @test 16 in ax
        end

        @testset "minimum()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(5, 10, "x", trailer)
            axDom = SeaPearl.IntDomainViewMul(x.domain, 4)

            @test SeaPearl.minimum(axDom) == 20
        end

        @testset "removeAll!()" begin
            trailer = SeaPearl.Trailer()
            dom = SeaPearl.IntDomain(trailer, 3, 10)
            axDom = SeaPearl.IntDomainViewMul(dom, 4)

            removed = SeaPearl.removeAll!(axDom)

            @test isempty(axDom)
            @test removed == [44, 48, 52]
        end

        
        @testset "maximum()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(5, 10, "x", trailer)
            axDom = SeaPearl.IntDomainViewMul(x.domain, 4)

            @test SeaPearl.maximum(axDom) == 40
        end

        @testset "remove!()" begin
            trailer = SeaPearl.Trailer()
            dom = SeaPearl.IntDomain(trailer, 3, 2)
            ax = SeaPearl.IntDomainViewMul(dom, 4)

            @test SeaPearl.remove!(ax, 12) == [12]


            @test !(12 in ax)
            @test length(ax) == 2
            @test SeaPearl.minimum(ax) == 16
        end

        @testset "removeAbove!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewMul(x.domain, 4)

            @test sort(SeaPearl.removeAbove!(axDom, 8)) == [12, 16, 20]

            @test length(axDom) == 2
            @test 8 in axDom
            @test 4 in axDom
            @test !(12 in axDom)

            @test sort(SeaPearl.removeAbove!(axDom, 2)) == [4, 8]

            @test isempty(axDom)

            
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewMul(x.domain, 4)

            @test sort(SeaPearl.removeAbove!(axDom, 10)) == [12, 16, 20]
            @test length(axDom) == 2
            @test 8 in axDom
            @test 4 in axDom
            @test !(12 in axDom)
        end

        @testset "removeBelow!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewMul(x.domain, 4)

            @test sort(SeaPearl.removeBelow!(axDom, 8)) == [4]

            @test length(axDom) == 4
            @test 8 in axDom
            @test 12 in axDom
            @test !(4 in axDom)

            @test sort(SeaPearl.removeBelow!(axDom, 21)) == [8, 12, 16, 20]

            @test isempty(axDom)

            
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewMul(x.domain, 4)

            @test sort(SeaPearl.removeBelow!(axDom, 6)) == [4]
            
            @test length(axDom) == 4
            @test 8 in axDom
            @test 12 in axDom
            @test !(4 in axDom)
        end

        @testset "iterate()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewMul(x.domain, 4)

            j = 4
            for i in axDom
                @test j == i
                j += 4
            end

            @test j == 24

        end

        @testset "updateMinFromRemovedVal!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewMul(x.domain, 4)

            @test SeaPearl.minimum(axDom) == 4

            SeaPearl.remove!(axDom, 4)
            SeaPearl.updateMinFromRemovedVal!(axDom, 4)

            @test SeaPearl.minimum(axDom) == 8
        end

        @testset "updateMaxFromRemovedVal!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewMul(x.domain, 4)

            @test SeaPearl.maximum(axDom) == 20

            SeaPearl.remove!(axDom, 20)
            SeaPearl.updateMaxFromRemovedVal!(axDom, 20)

            @test SeaPearl.maximum(axDom) == 16
        end

        @testset "updateBoundsFromRemovedVal!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewMul(x.domain, 4)

            SeaPearl.remove!(axDom, 20)
            SeaPearl.remove!(axDom, 4)
            SeaPearl.updateBoundsFromRemovedVal!(axDom, 20)
            SeaPearl.updateBoundsFromRemovedVal!(axDom, 4)

            @test SeaPearl.minimum(axDom) == 8
            @test SeaPearl.maximum(axDom) == 16
        end

        @testset "isbound()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(2, 6, "x", trailer)
            ax = SeaPearl.IntVarViewMul(x, 3, "ax")

            @test !SeaPearl.isbound(ax)

            SeaPearl.assign!(ax, 6)

            @test SeaPearl.isbound(ax)
        end

        @testset "assignedValue()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(5, 5, "x", trailer)
            ax = SeaPearl.IntVarViewMul(x, 3, "ax")

            @test SeaPearl.assignedValue(ax) == 15

            y = SeaPearl.IntVar(5, 8, "y", trailer)
            ay = SeaPearl.IntVarViewMul(y, 3, "ay")
            @test_throws AssertionError SeaPearl.assignedValue(y)
        end

        @testset "rootVariable()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(5, 5, "x", trailer)
            ax = SeaPearl.IntVarViewMul(x, 3, "ax")

            @test SeaPearl.rootVariable(SeaPearl.IntVarViewOpposite(ax, "-ax")) == x

            @test SeaPearl.rootVariable(x) == x
            @test SeaPearl.rootVariable(ax) == x
        end
    end
    @testset "IntVarViewOpposite" begin
    
        @testset "isempty()" begin
            trailer = SeaPearl.Trailer()
            domNotEmpty = SeaPearl.IntDomain(trailer, 20, 10)
            ax = SeaPearl.IntDomainViewOpposite(domNotEmpty)

            @test !isempty(ax)

            emptyDom = SeaPearl.IntDomain(trailer, 0, 1)
            ay = SeaPearl.IntDomainViewOpposite(emptyDom)
            @test isempty(ay)
        end

        @testset "length()" begin
            trailer = SeaPearl.Trailer()
            dom20 = SeaPearl.IntDomain(trailer, 20, 10)
            ax = SeaPearl.IntDomainViewOpposite(dom20)
            @test length(ax) == 20

            dom2 = SeaPearl.IntDomain(trailer, 2, 0)
            ax = SeaPearl.IntDomainViewOpposite(dom2)

            @test length(ax) == 2
        end

        @testset "in()" begin
            trailer = SeaPearl.Trailer()
            dom20 = SeaPearl.IntDomain(trailer, 3, 2)
            ax = SeaPearl.IntDomainViewOpposite(dom20)

            @test !(4 in ax)
            @test !(3 in ax)
            @test -3 in ax
            @test !(-6 in ax)
            @test -5 in ax
        end

        @testset "minimum()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(5, 10, "x", trailer)
            axDom = SeaPearl.IntDomainViewOpposite(x.domain)

            @test SeaPearl.minimum(axDom) == -10
        end

        @testset "removeAll!()" begin
            trailer = SeaPearl.Trailer()
            dom = SeaPearl.IntDomain(trailer, 3, 10)
            axDom = SeaPearl.IntDomainViewOpposite(dom)

            removed = SeaPearl.removeAll!(axDom)

            @test isempty(axDom)
            @test removed == [-11, -12, -13]
        end

        
        @testset "maximum()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(5, 10, "x", trailer)
            axDom = SeaPearl.IntDomainViewOpposite(x.domain)

            @test SeaPearl.maximum(axDom) == -5
        end

        @testset "remove!()" begin
            trailer = SeaPearl.Trailer()
            dom = SeaPearl.IntDomain(trailer, 3, 2)
            ax = SeaPearl.IntDomainViewOpposite(dom)

            @test SeaPearl.remove!(ax, -5) == [-5]


            @test !(-5 in ax)
            @test length(ax) == 2
            @test SeaPearl.minimum(ax) == -4
        end

        @testset "removeAbove!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOpposite(x.domain)

            @test sort(SeaPearl.removeAbove!(axDom, -4)) == [-3, -2, -1]

            @test length(axDom) == 2
            @test -4 in axDom
            @test -5 in axDom
            @test !(-3 in axDom)

            @test sort(SeaPearl.removeAbove!(axDom, -6)) == [-5, -4]

            @test isempty(axDom)
        end

        @testset "removeBelow!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOpposite(x.domain)

            @test sort(SeaPearl.removeBelow!(axDom, -4)) == [-5]

            @test length(axDom) == 4
            @test -4 in axDom
            @test -3 in axDom
            @test !(-5 in axDom)

            @test sort(SeaPearl.removeBelow!(axDom, 0)) == [-4, -3, -2, -1]

            @test isempty(axDom)
        end

        @testset "iterate()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOpposite(x.domain)

            j = -1
            for i in axDom
                @test j == i
                j -= 1
            end

            @test j == -6

        end

        @testset "updateMinFromRemovedVal!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOpposite(x.domain)

            @test SeaPearl.minimum(axDom) == -5

            SeaPearl.remove!(axDom, -5)
            SeaPearl.updateMinFromRemovedVal!(axDom, -5)

            @test SeaPearl.minimum(axDom) == -4
        end

        @testset "updateMaxFromRemovedVal!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOpposite(x.domain)

            @test SeaPearl.maximum(axDom) == -1

            SeaPearl.remove!(axDom, -1)
            SeaPearl.updateMaxFromRemovedVal!(axDom, -1)

            @test SeaPearl.maximum(axDom) == -2
        end

        @testset "updateBoundsFromRemovedVal!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOpposite(x.domain)

            SeaPearl.remove!(axDom, -5)
            SeaPearl.remove!(axDom, -1)
            SeaPearl.updateBoundsFromRemovedVal!(axDom, -5)
            SeaPearl.updateBoundsFromRemovedVal!(axDom, -1)

            @test SeaPearl.minimum(axDom) == -4
            @test SeaPearl.maximum(axDom) == -2
        end

        @testset "isbound()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(2, 6, "x", trailer)
            ax = SeaPearl.IntVarViewOpposite(x, "-x")

            @test !SeaPearl.isbound(ax)

            SeaPearl.assign!(ax, -5)

            @test SeaPearl.isbound(ax)
        end

        @testset "assignedValue()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(5, 5, "x", trailer)
            ax = SeaPearl.IntVarViewOpposite(x, "-x")

            @test SeaPearl.assignedValue(ax) == -5

            y = SeaPearl.IntVar(5, 8, "y", trailer)
            ay = SeaPearl.IntVarViewOpposite(y, "-y")
            @test_throws AssertionError SeaPearl.assignedValue(y)
        end

        @testset "rootVariable()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(5, 5, "x", trailer)
            ax = SeaPearl.IntVarViewOpposite(x, "-x")

            @test SeaPearl.rootVariable(x) == x
            @test SeaPearl.rootVariable(ax) == x
        end
    end

    @testset "IntVarViewOffset" begin
        @testset "isempty()" begin
            trailer = SeaPearl.Trailer()
            domNotEmpty = SeaPearl.IntDomain(trailer, 20, 10)
            ax = SeaPearl.IntDomainViewOffset(domNotEmpty, 4)

            @test !isempty(ax)

            emptyDom = SeaPearl.IntDomain(trailer, 0, 1)
            ay = SeaPearl.IntDomainViewOffset(emptyDom, 4)
            @test isempty(ay)
        end

        @testset "length()" begin
            trailer = SeaPearl.Trailer()
            dom20 = SeaPearl.IntDomain(trailer, 20, 10)
            ax = SeaPearl.IntDomainViewOffset(dom20, 4)
            @test length(ax) == 20

            dom2 = SeaPearl.IntDomain(trailer, 2, 0)
            ax = SeaPearl.IntDomainViewOffset(dom2, 4)

            @test length(ax) == 2
        end

        @testset "in()" begin
            trailer = SeaPearl.Trailer()
            dom20 = SeaPearl.IntDomain(trailer, 3, 2)
            ax = SeaPearl.IntDomainViewOffset(dom20, 4)

            @test !(2 in ax)
            @test !(3 in ax)
            @test 7 in ax
            @test !(10 in ax)
            @test 9 in ax
        end

        @testset "minimum()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(5, 10, "x", trailer)
            axDom = SeaPearl.IntDomainViewOffset(x.domain, 4)

            @test SeaPearl.minimum(axDom) == 9
        end

        @testset "removeAll!()" begin
            trailer = SeaPearl.Trailer()
            dom = SeaPearl.IntDomain(trailer, 3, 10)
            axDom = SeaPearl.IntDomainViewOffset(dom, 4)

            removed = SeaPearl.removeAll!(axDom)

            @test isempty(axDom)
            @test removed == [15, 16, 17]
        end

        
        @testset "maximum()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(5, 10, "x", trailer)
            axDom = SeaPearl.IntDomainViewOffset(x.domain, 4)

            @test SeaPearl.maximum(axDom) == 14
        end

        @testset "remove!()" begin
            trailer = SeaPearl.Trailer()
            dom = SeaPearl.IntDomain(trailer, 3, 2)
            ax = SeaPearl.IntDomainViewOffset(dom, 4)

            SeaPearl.remove!(ax, 7)


            @test !(7 in ax)
            @test length(ax) == 2
            @test SeaPearl.minimum(ax) == 8
        end

        @testset "removeAbove!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOffset(x.domain, 4)

            @test sort(SeaPearl.removeAbove!(axDom, 7)) == [8, 9]

            @test length(axDom) == 3
            @test 7 in axDom
            @test !(4 in axDom)
            @test !(9 in axDom)
            @test 5 in axDom

            @test sort(SeaPearl.removeAbove!(axDom, 2)) == [5, 6, 7]

            @test isempty(axDom)
        end

        @testset "removeBelow!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOffset(x.domain, 4)

            @test sort(SeaPearl.removeBelow!(axDom, 8)) == [5, 6, 7]

            @test length(axDom) == 2
            @test 8 in axDom
            @test 9 in axDom
            @test !(5 in axDom)
            @test !(4 in axDom)

            @test sort(SeaPearl.removeBelow!(axDom, 21)) == [8, 9]

            @test isempty(axDom)
        end

        @testset "iterate()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOffset(x.domain, 4)

            j = 5
            for i in axDom
                @test j == i
                j += 1
            end

            @test j == 10

        end

        @testset "updateMinFromRemovedVal!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOffset(x.domain, 4)

            @test SeaPearl.minimum(axDom) == 5

            SeaPearl.remove!(axDom, 5)
            SeaPearl.updateMinFromRemovedVal!(axDom, 5)

            @test SeaPearl.minimum(axDom) == 6
        end

        @testset "updateMaxFromRemovedVal!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOffset(x.domain, 4)

            @test SeaPearl.maximum(axDom) == 9

            SeaPearl.remove!(axDom, 9)
            SeaPearl.updateMaxFromRemovedVal!(axDom, 9)

            @test SeaPearl.maximum(axDom) == 8
        end

        @testset "updateBoundsFromRemovedVal!()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(1, 5, "x", trailer)
            axDom = SeaPearl.IntDomainViewOffset(x.domain, 4)

            SeaPearl.remove!(axDom, 9)
            SeaPearl.remove!(axDom, 5)
            SeaPearl.updateBoundsFromRemovedVal!(axDom, 9)
            SeaPearl.updateBoundsFromRemovedVal!(axDom, 5)

            @test SeaPearl.minimum(axDom) == 6
            @test SeaPearl.maximum(axDom) == 8
        end

        @testset "isbound()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(2, 6, "x", trailer)
            ax = SeaPearl.IntVarViewOffset(x, 3, "ax")

            @test !SeaPearl.isbound(ax)

            SeaPearl.assign!(ax, 6)

            @test SeaPearl.isbound(ax)
        end

        @testset "assignedValue()" begin
            trailer = SeaPearl.Trailer()
            x = SeaPearl.IntVar(5, 5, "x", trailer)
            ax = SeaPearl.IntVarViewOffset(x, 3, "ax")

            @test SeaPearl.assignedValue(ax) == 8

            y = SeaPearl.IntVar(5, 8, "y", trailer)
            ay = SeaPearl.IntVarViewOffset(y, 3, "ay")
            @test_throws AssertionError SeaPearl.assignedValue(y)
        end
    end
end
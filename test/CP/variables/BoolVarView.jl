@testset "BoolVarView.jl" begin
    @testset "BoolVarViewNot" begin
        @testset "isempty()" begin
            trailer = SeaPearl.Trailer()
            orig = SeaPearl.BoolDomain(trailer)
            dom = SeaPearl.BoolDomainViewNot(orig)

            @test !isempty(dom)

            SeaPearl.remove!(orig, false)
            SeaPearl.remove!(orig, true)
            @test isempty(dom)
            
            trailer = SeaPearl.Trailer()
            orig = SeaPearl.BoolDomain(trailer)
            dom = SeaPearl.BoolDomainViewNot(orig)

            @test !isempty(dom)

            SeaPearl.remove!(dom, false)
            SeaPearl.remove!(dom, true)
            @test isempty(dom)
        end

        @testset "length()" begin
            trailer = SeaPearl.Trailer()
            orig = SeaPearl.BoolDomain(trailer)
            dom = SeaPearl.BoolDomainViewNot(orig)
            @test length(dom) == 2

            SeaPearl.remove!(dom, false)
            @test length(dom) == 1

            SeaPearl.remove!(dom, true)
            @test length(dom) == 0

            trailer = SeaPearl.Trailer()
            orig = SeaPearl.BoolDomain(trailer)
            dom = SeaPearl.BoolDomainViewNot(orig)
            @test length(dom) == 2

            SeaPearl.remove!(orig, false)
            @test length(dom) == 1

            SeaPearl.remove!(orig, true)
            @test length(dom) == 0
        end

        @testset "in()" begin
            trailer = SeaPearl.Trailer()
            orig = SeaPearl.BoolDomain(trailer)
            dom = SeaPearl.BoolDomainViewNot(orig)

            @test true in dom
            @test false in dom
            SeaPearl.remove!(orig, false)
            @test !(true in dom)
            @test false in dom
        end

        @testset "remove!()" begin
            trailer = SeaPearl.Trailer()
            orig = SeaPearl.BoolDomain(trailer)
            dom = SeaPearl.BoolDomainViewNot(orig)

            SeaPearl.remove!(dom, false)

            @test !(false in dom)
            @test length(dom) == 1
        end

        @testset "assign!()" begin
            trailer = SeaPearl.Trailer()
            orig = SeaPearl.BoolDomain(trailer)
            dom = SeaPearl.BoolDomainViewNot(orig)

            removed = SeaPearl.assign!(dom, true)

            @test !(false in dom)
            @test true in dom
            @test length(dom) == 1
            @test sort(removed) == [false]
            @test false in orig
            @test !(true in orig)
        end

        @testset "iterate()" begin
            trailer = SeaPearl.Trailer()
            orig = SeaPearl.BoolDomain(trailer)
            dom = SeaPearl.BoolDomainViewNot(orig)

            j = 1
            for i in dom
                if i == 1
                    @test i
                else
                    @test !i
                end
                j += 1
            end
            @test j == 3
        end

        @testset "removeAll!()" begin
            trailer = SeaPearl.Trailer()
            orig = SeaPearl.BoolDomain(trailer)
            dom = SeaPearl.BoolDomainViewNot(orig)

            removed = SeaPearl.removeAll!(dom)

            @test isempty(dom)
            @test removed == [true, false]
        end
    end
end
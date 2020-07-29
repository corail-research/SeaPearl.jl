@testset "BoolDomain.jl" begin
    @testset "isempty()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.BoolDomain(trailer)

        @test !isempty(dom)

        SeaPearl.remove!(dom, false)
        SeaPearl.remove!(dom, true)
        @test isempty(dom)
    end

    @testset "length()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.BoolDomain(trailer)
        @test length(dom) == 2

        SeaPearl.remove!(dom, false)
        @test length(dom) == 1

        SeaPearl.remove!(dom, true)
        @test length(dom) == 0
    end

    @testset "in()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.BoolDomain(trailer)

        @test true in dom
        @test false in dom
        SeaPearl.remove!(dom, false)
        @test !(false in dom)
    end

    @testset "remove!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.BoolDomain(trailer)

        SeaPearl.remove!(dom, false)


        @test !(false in dom)
        @test length(dom) == 1
    end

    @testset "assign!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.BoolDomain(trailer)

        removed = SeaPearl.assign!(dom, true)

        @test !(false in dom)
        @test true in dom
        @test length(dom) == 1
        @test sort(removed) == [false]
    end

    @testset "iterate()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.BoolDomain(trailer)

        j = 1
        for i in dom
            if i == 1
                @test !i
            else
                @est i
            end
            j += 1
        end
        @test j == 3
    end

    @testset "removeAll!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.BoolDomain(trailer)

        removed = SeaPearl.removeAll!(dom)

        @test isempty(dom)
        @test removed == [false, true]
    end
end
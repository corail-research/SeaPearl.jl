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
        @test 1 in dom
        @test false in dom
        @test 0 in dom
        @test !(2 in dom)
        @test !(-1 in dom)
        SeaPearl.remove!(dom, false)
        @test !(false in dom)
        @test !(0 in dom)
    end

    @testset "remove!(::Bool)" begin
        trailer = SeaPearl.Trailer()

        dom = SeaPearl.BoolDomain(trailer)
        SeaPearl.remove!(dom, false)
        @test !(false in dom)
        @test length(dom) == 1

        dom = SeaPearl.BoolDomain(trailer)
        SeaPearl.remove!(dom, true)
        @test !(true in dom)
        @test length(dom) == 1
        SeaPearl.remove!(dom, false)
        @test isempty(dom)
    end

    @testset "remove!(::Int)" begin
        trailer = SeaPearl.Trailer()

        dom = SeaPearl.BoolDomain(trailer)
        SeaPearl.remove!(dom, 0)
        @test !(false in dom)
        @test length(dom) == 1

        dom = SeaPearl.BoolDomain(trailer)
        SeaPearl.remove!(dom, 1)
        @test !(true in dom)
        @test length(dom) == 1
        SeaPearl.remove!(dom, 0)
        @test isempty(dom)
    end

    @testset "removeAbove!()" begin
        trailer = SeaPearl.Trailer()

        dom = SeaPearl.BoolDomain(trailer)
        removed = SeaPearl.removeAbove!(dom, 0)
        @test false in dom
        @test length(dom) == 1
        @test removed == [true]

        dom = SeaPearl.BoolDomain(trailer)
        removed = SeaPearl.removeAbove!(dom, 1)
        @test length(dom) == 2
        @test removed == []
    end

    @testset "removeBelow!()" begin
        trailer = SeaPearl.Trailer()

        dom = SeaPearl.BoolDomain(trailer)
        removed = SeaPearl.removeBelow!(dom, 0)
        @test length(dom) == 2
        @test removed == []

        dom = SeaPearl.BoolDomain(trailer)
        removed = SeaPearl.removeBelow!(dom, 1)
        @test true in dom
        @test length(dom) == 1
        @test removed == [false]
    end

    @testset "assign!(::Bool)" begin
        trailer = SeaPearl.Trailer()

        dom = SeaPearl.BoolDomain(trailer)
        removed = SeaPearl.assign!(dom, true)
        @test !(false in dom)
        @test true in dom
        @test length(dom) == 1
        @test removed == [false]

        dom = SeaPearl.BoolDomain(trailer)
        removed = SeaPearl.assign!(dom, false)
        @test !(true in dom)
        @test false in dom
        @test length(dom) == 1
        @test removed == [true]
    end

    @testset "assign!(::Int)" begin
        trailer = SeaPearl.Trailer()

        dom = SeaPearl.BoolDomain(trailer)
        removed = SeaPearl.assign!(dom, 1)
        @test !(false in dom)
        @test true in dom
        @test length(dom) == 1
        @test removed == [false]

        dom = SeaPearl.BoolDomain(trailer)
        removed = SeaPearl.assign!(dom, 0)
        @test !(true in dom)
        @test false in dom
        @test length(dom) == 1
        @test removed == [true]
    end

    @testset "iterate()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.BoolDomain(trailer)

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
        dom = SeaPearl.BoolDomain(trailer)

        removed = SeaPearl.removeAll!(dom)

        @test isempty(dom)
        @test removed == [false, true]
    end

    @testset "minimum()" begin
        trailer = SeaPearl.Trailer()

        dom = SeaPearl.BoolDomain(trailer)
        @test SeaPearl.minimum(dom) == 0
        @test SeaPearl.minimum(dom) == false

        SeaPearl.remove!(dom, false)
        @test SeaPearl.minimum(dom) == 1
        @test SeaPearl.minimum(dom) == true
    end
    
    @testset "maximum()" begin
        trailer = SeaPearl.Trailer()

        dom = SeaPearl.BoolDomain(trailer)
        @test SeaPearl.maximum(dom) == 1
        @test SeaPearl.maximum(dom) == true

        SeaPearl.remove!(dom, true)
        @test SeaPearl.maximum(dom) == 0
        @test SeaPearl.maximum(dom) == false
    end
end
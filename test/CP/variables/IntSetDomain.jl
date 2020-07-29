@testset "IntSetDomain.jl" begin
    @testset "IntSetDomain()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntSetDomain(trailer, 10, 20)

        
    end

    @testset "exclude!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntSetDomain(trailer, 10, 20)

        SeaPearl.saveState!(trailer)

        SeaPearl.exclude!(dom, 11)

        @test !SeaPearl.is_possible(dom, 11)

        SeaPearl.restoreState!(trailer)

        @test SeaPearl.is_possible(dom, 11)
    end

    @testset "require!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntSetDomain(trailer, 10, 20)

        SeaPearl.saveState!(trailer)

        SeaPearl.require!(dom, 11)

        @test SeaPearl.is_possible(dom, 11)
        @test SeaPearl.is_required(dom, 11)


        SeaPearl.restoreState!(trailer)

        @test SeaPearl.is_possible(dom, 11)
        @test !SeaPearl.is_required(dom, 11)
    end

    @testset "is_possible()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntSetDomain(trailer, 10, 20)

        SeaPearl.require!(dom, 11)
        SeaPearl.exclude!(dom, 10)

        @test SeaPearl.is_possible(dom, 11)
        @test SeaPearl.is_possible(dom, 12)
        @test !SeaPearl.is_possible(dom, 10)
        @test !SeaPearl.is_possible(dom, 9)
    end

    @testset "is_required()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntSetDomain(trailer, 10, 20)

        SeaPearl.require!(dom, 11)
        SeaPearl.exclude!(dom, 10)

        @test SeaPearl.is_required(dom, 11)
        @test !SeaPearl.is_required(dom, 12)
        @test !SeaPearl.is_possible(dom, 10)
        @test !SeaPearl.is_possible(dom, 9)
    end

    @testset "required_values()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntSetDomain(trailer, 10, 13)

        @test SeaPearl.required_values(dom) == Set{Int}()

        SeaPearl.require!(dom, 11)
        SeaPearl.require!(dom, 12)

        @test SeaPearl.required_values(dom) == Set{Int}([11, 12])
    end

    @testset "possible_not_required_values()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntSetDomain(trailer, 10, 13)

        @test SeaPearl.possible_not_required_values(dom) == Set{Int}([10, 11, 12, 13])

        SeaPearl.require!(dom, 11)
        SeaPearl.require!(dom, 12)

        @test SeaPearl.possible_not_required_values(dom) == Set{Int}([10, 13])
    end

    

    @testset "exchangePositions!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntSetDomain(trailer, 5, 10)

        @test dom.values == [1, 2, 3, 4, 5, 6]
        @test dom.indexes == [1, 2, 3, 4, 5, 6]

        SeaPearl.exchangePositions!(dom, 6, 9)

        @test dom.values == [1, 5, 3, 4, 2, 6]
        @test dom.indexes == [1, 5, 3, 4, 2, 6]

        SeaPearl.exchangePositions!(dom, 9, 5)

        @test dom.values == [2, 5, 3, 4, 1, 6]
        @test dom.indexes == [5, 1, 3, 4, 2, 6]
    end
end
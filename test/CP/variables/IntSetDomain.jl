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

        @test SeaPearl.is_possible(dom, 10)
        @test !SeaPearl.is_required(dom, 10)

        SeaPearl.require!(dom, 10)

        @test SeaPearl.is_possible(dom, 10)
        @test SeaPearl.is_required(dom, 10)


        SeaPearl.restoreState!(trailer)

        @test SeaPearl.is_possible(dom, 10)
        @test !SeaPearl.is_required(dom, 10)
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

        @test dom.values == [5, 1, 3, 4, 2, 6]
        @test dom.indexes == [2, 5, 3, 4, 1, 6]
    end

    @testset "require_all!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntSetDomain(trailer, 10, 13)
        SeaPearl.exclude!(dom, 12)
        SeaPearl.require!(dom, 11)

        SeaPearl.saveState!(trailer)

        SeaPearl.require_all!(dom)

        @test SeaPearl.required_values(dom) == Set{Int}([10, 11, 13])
        @test SeaPearl.possible_not_required_values(dom) == Set{Int}()

        SeaPearl.restoreState!(trailer)

        @test SeaPearl.required_values(dom) == Set{Int}([11])
        @test SeaPearl.possible_not_required_values(dom) == Set{Int}([10, 13])
    end

    @testset "exclude_all!()" begin
        trailer = SeaPearl.Trailer()
        dom = SeaPearl.IntSetDomain(trailer, 10, 13)
        SeaPearl.exclude!(dom, 12)
        SeaPearl.require!(dom, 11)

        SeaPearl.saveState!(trailer)

        SeaPearl.exclude_all!(dom)

        @test SeaPearl.required_values(dom) == Set{Int}([11])
        @test SeaPearl.possible_not_required_values(dom) == Set{Int}()

        SeaPearl.restoreState!(trailer)

        @test SeaPearl.required_values(dom) == Set{Int}([11])
        @test SeaPearl.possible_not_required_values(dom) == Set{Int}([10, 13])
    end

    @testset "reset_domain!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntSetVar(5, 10, "x", trailer)
        
        SeaPearl.exclude!(x.domain, 6)
        SeaPearl.require!(x.domain, 8)
        
        @test x.domain.values == [4, 6, 3, 1, 5, 2]
        @test x.domain.indexes == [4, 6, 3, 1, 5, 2]
        @test SeaPearl.length(SeaPearl.required_values(x.domain)) == 1
        @test SeaPearl.length(SeaPearl.possible_not_required_values(x.domain)) == 4
        SeaPearl.reset_domain!(x.domain)
        @test x.domain.values == [1, 2, 3, 4, 5, 6]
        @test x.domain.indexes == [1, 2, 3, 4, 5, 6]
        @test SeaPearl.length(SeaPearl.required_values(x.domain)) == 0
        @test SeaPearl.length(SeaPearl.possible_not_required_values(x.domain)) == 6
    end
end
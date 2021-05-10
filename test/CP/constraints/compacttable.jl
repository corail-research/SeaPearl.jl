@testset "compacctable.jl" begin
    @testset "cleanTable(variables::Vector{<:AbstractIntVar}, table::Matrix{Int})::Matrix{Int}" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = Vector{SeaPearl.AbstractIntVar}([x, y, z])
        table = [
            1 2 2;
            3 3 3;
            1 2 3
        ]
        res = SeaPearl.cleanTable(vec, table)
        @test all(res .== [2 2; 3 3; 2 3])
    end
    @testset "buildSupport(variables::Vector{<:AbstractIntVar}, table::Matrix{Int})::Dict{Pair{Int,Int},BitVector}" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = Vector{SeaPearl.AbstractIntVar}([x, y, z])
        table = [
            1 2 2;
            3 3 3;
            1 2 3
        ]
        table = SeaPearl.cleanTable(vec, table)
        support = SeaPearl.buildSupport(vec, table)
        @test support[2 => 3] == [1,1]
        @test support[1 => 1] == [0,0]
    end
    @testset "cleanSupports!(supports::Dict{Pair{Int,Int},BitVector}, variables::Vector{<:AbstractIntVar})::Nothing" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = Vector{SeaPearl.AbstractIntVar}([x, y, z])
        table = [
            1 2 2;
            3 3 3;
            1 2 3
        ]
        table = SeaPearl.cleanTable(vec, table)
        @test !(1 in y.domain)
        support = SeaPearl.buildSupport(vec,table)
        SeaPearl.cleanSupports!(support, vec)
        @test !(1 in x.domain)
    end
    @testset "TableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Int}, trailer)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = Vector{SeaPearl.AbstractIntVar}([x, y, z])
        table = [
            1 2 2;
            3 3 3;
            1 2 3
        ]
        constraint = SeaPearl.TableConstraint(vec, table, trailer)
        @test size(constraint.table, 2)==2
        @test all(constraint.lastSizes.==[3, 2, 2])
        @test (constraint.supports[3=>2] == [1,0])
        @test(isempty(constraint.modifiedVariables))
        @test(constraint.residues[3=>2]==1)
    end
    @testset "propagate!(constraint::TableConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "z", trailer)
        SeaPearl.remove!(z.domain, 2)
        a = SeaPearl.IntVar(2, 4, "a", trailer)
        SeaPearl.remove!(a.domain, 3)
        b = SeaPearl.IntVar(3, 6, "b", trailer)
        c = SeaPearl.IntVar(6, 7, "c", trailer)

        table = [
            1 2 2;
            3 3 3;
            1 2 3;
            2 5 4;
            3 7 6;
            5 7 7
        ]
        vec = Vector{SeaPearl.AbstractIntVar}([x, y, z, a, b, c])
        table = SeaPearl.cleanTable(vec,table)

        constraint = SeaPearl.TableConstraint(vec, table, trailer)

        toPropagate = Set{SeaPearl.Constraint}([constraint])
        modif = SeaPearl.CPModification(Dict("z" => [2]))
        SeaPearl.remove!(z.domain, 1)
        res = SeaPearl.propagate!(constraint, toPropagate, modif)

        @test !(constraint in toPropagate)

        @test length(x.domain) == 1
        @test length(y.domain) == 1
        @test length(z.domain) == 1
        @test length(a.domain) == 1
        @test length(b.domain) == 1
        @test length(c.domain) == 1
        @test 2 in x.domain
        @test !(1 in z.domain)

    end
end

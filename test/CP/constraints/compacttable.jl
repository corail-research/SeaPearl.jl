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
        vec = [x, y, z]
        table = [
            1 2 2;
            3 3 3;
            1 2 3
        ]
        table = SeaPearl.cleanTable(vec, table)
        support = SeaPearl.buildSupport(vec,table)
        @test all([(i => j) in keys(support) for i = 1:3, j = 2:3])
        @test (1 => 1) in keys(support)
        SeaPearl.cleanSupports!(support, vec)
        @test !((1 => 1) in keys(support))
        @test !((1 => 3) in keys(support))
        @test !((2 => 2) in keys(support))
        @test !((3 => 1) in keys(support))
        @test length(keys(support)) == 4
    end
    @testset "TableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Int}, supports::Dict{Pair{Int,Int},BitVector}, trailer)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 3, "y", trailer)
        z = SeaPearl.IntVar(1, 3, "Z", trailer)
        vec1 = [x, y, z]
        vec2 = [z, y, x]
        table = [
            1 2 2;
            3 3 3;
            1 2 3
        ]
        supports = SeaPearl.buildSupport(vec1, table)
        SeaPearl.cleanSupports!(supports, vec1)
        table = SeaPearl.cleanTable(vec1, table)
        constraint1 = SeaPearl.TableConstraint(vec1, table, supports, trailer)
        constraint2 = SeaPearl.TableConstraint(vec2, table, supports, trailer)
        @test size(constraint1.table, 2)==3
        @test size(constraint2.table, 2)==3
        @test (constraint1.supports[3=>2] == [0,1,0])
        @test (constraint2.supports[3=>2] == [0,1,0])
        @test(isempty(constraint1.modifiedVariables))
        @test(isempty(constraint2.modifiedVariables))
        @test(constraint1.residues[3=>2]==1)
        @test(constraint2.residues[3=>2]==1)
    end
    @testset "TableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Int}, trailer)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = [x, y, z]
        table = [
            1 2 2;
            3 3 3;
            1 2 3
        ]
        constraint = SeaPearl.TableConstraint(vec, table, trailer)
        @test size(constraint.table, 2)==2
        @test (constraint.supports[3=>2] == [1,0])
        @test(isempty(constraint.modifiedVariables))
        @test(constraint.residues[3=>2]==1)
    end
    @testset "propagate!(constraint::TableConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "z", trailer)
        a = SeaPearl.IntVar(2, 4, "a", trailer)
        SeaPearl.remove!(a.domain, 3)
        b = SeaPearl.IntVar(3, 6, "b", trailer)
        c = SeaPearl.IntVar(5, 7, "c", trailer)

        table = [
            1 2 2;
            3 3 3;
            1 2 3;
            2 5 4;
            3 7 6;
            5 7 7
        ]
        vec = [x, y, z, a, b, c]
        table = SeaPearl.cleanTable(vec,table)

        constraint = SeaPearl.TableConstraint(vec, table, trailer)

        toPropagate = Set{SeaPearl.Constraint}([constraint])
        modif = SeaPearl.CPModification()
        res = SeaPearl.propagate!(constraint, toPropagate, modif)

        @test !(constraint in toPropagate)

        @test length(x.domain) == 1
        @test length(y.domain) == 1
        @test length(z.domain) == 1
        @test length(a.domain) == 1
        @test length(b.domain) == 1
        @test length(c.domain) == 1
        @test 2 in x.domain
        @test 3 in y.domain
        @test 3 in z.domain
        @test 4 in a.domain
        @test 6 in b.domain
        @test 7 in c.domain
    end

    @testset "compactTable fullPropagation" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 3, "y", trailer)
        z = SeaPearl.IntVar(1, 3, "z", trailer)
        a = SeaPearl.IntVar(1, 3, "a", trailer)
        b = SeaPearl.IntVar(1, 3, "b", trailer)
        c = SeaPearl.IntVar(1, 3, "c", trailer)

        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z)
        SeaPearl.addVariable!(model, a)
        SeaPearl.addVariable!(model, b)
        SeaPearl.addVariable!(model, c)
        table1 = [
            1 2 3 1 2 3;
            1 1 2 2 3 3;
            1 1 1 3 3 3;
            3 2 1 3 2 1
        ]
        table2 = [
            1 2 3;
            1 2 3;
            1 2 3
        ]

        constraint1 = SeaPearl.TableConstraint([x, y, z, a], table1, trailer)
        constraint2 = SeaPearl.TableConstraint([a, b, c], table2, trailer)

        SeaPearl.addConstraint!(model, constraint1)
        SeaPearl.addConstraint!(model, constraint2)

        variableSelection = SeaPearl.MinDomainVariableSelection{false}()
        SeaPearl.solve!(model; variableHeuristic=variableSelection)
        
        @test length(model.statistics.solutions) == 6
        @test Dict("c" => 2, "x" => 2, "b" => 2, "z" => 3, "a" => 2, "y" => 3) in model.statistics.solutions
        @test Dict("c" => 1, "x" => 3, "b" => 1, "z" => 3, "a" => 1, "y" => 3) in model.statistics.solutions
        @test Dict("c" => 3, "x" => 1, "b" => 3, "z" => 3, "a" => 3, "y" => 2) in model.statistics.solutions
        @test Dict("c" => 1, "x" => 3, "b" => 1, "z" => 1, "a" => 1, "y" => 2) in model.statistics.solutions
        @test Dict("c" => 3, "x" => 1, "b" => 3, "z" => 1, "a" => 3, "y" => 1) in model.statistics.solutions
        @test Dict("c" => 2, "x" => 2, "b" => 2, "z" => 1, "a" => 2, "y" => 1) in model.statistics.solutions
    end
end

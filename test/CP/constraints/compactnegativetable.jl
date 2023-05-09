@testset "compactnegativetable.jl" begin
    @testset "cleanNegativeTable(variables::Vector{<:AbstractIntVar}, table::Matrix{Int})::Matrix{Int}" begin
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
        res = SeaPearl.cleanNegativeTable(vec, table)
        @test all(res .== [2 2; 3 3; 2 3])
    end
    @testset "buildConflict(variables::Vector{<:AbstractIntVar}, table::Matrix{Int})::Dict{Pair{Int,Int},BitVector}" begin
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
        conflict = SeaPearl.buildConflict(vec, table)

        @test conflict[2 => 3] == [1,1]
        @test conflict[1 => 1] == [0,0]
    end
    @testset "cleanConflicts!(conflicts::Dict{Pair{Int,Int},BitVector}, variables::Vector{<:AbstractIntVar})::Nothing" begin
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
        conflict = SeaPearl.buildConflict(vec,table)
        @test all([(i => j) in keys(conflict) for i = 1:3, j = 2:3])
        @test (1 => 1) in keys(conflict)
        SeaPearl.cleanConflicts!(conflict, vec)
        @test !((1 => 1) in keys(conflict))
        @test !((1 => 3) in keys(conflict))
        @test !((2 => 2) in keys(conflict))
        @test !((3 => 1) in keys(conflict))
        @test length(keys(conflict)) == 4
    end
    @testset "NegativeTableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Int}, conflicts::Dict{Pair{Int,Int},BitVector}, trailer)" begin
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
        conflicts = SeaPearl.buildConflict(vec1, table)
        SeaPearl.cleanConflicts!(conflicts, vec1)
        table = SeaPearl.cleanTable(vec1, table)
        constraint1 = SeaPearl.NegativeTableConstraint(vec1, table, conflicts, trailer)
        constraint2 = SeaPearl.NegativeTableConstraint(vec2, table, conflicts, trailer)
        @test size(constraint1.table, 2)==3
        @test size(constraint2.table, 2)==3
        @test (constraint1.conflicts[3=>2] == [0,1,0])
        @test (constraint2.conflicts[3=>2] == [0,1,0])
        @test(isempty(constraint1.modifiedVariables))
        @test(isempty(constraint2.modifiedVariables))
        @test(constraint1.residues[3=>2]==1)
        @test(constraint2.residues[3=>2]==1)
    end
    @testset "NegativeTableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Int}, trailer)" begin
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
        constraint = SeaPearl.NegativeTableConstraint(vec, table, trailer)
        @test size(constraint.table, 2)==2
        @test (constraint.conflicts[3=>2] == [1,0])
        @test(isempty(constraint.modifiedVariables))
        @test(constraint.residues[3=>2]==1)
    end


    @testset "propagate!(constraint::TableConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(0, 1, "x", trailer)
        y = SeaPearl.IntVar(0, 1, "y", trailer)
        z = SeaPearl.IntVar(0, 1, "z", trailer)
        
        table = [
            0 1 0 0;
            0 0 1 0;
            0 0 0 1;
        ]
        vec = [x, y, z]
        table = SeaPearl.cleanNegativeTable(vec,table)
        
        constraint = SeaPearl.NegativeTableConstraint(vec, table, trailer)

        toPropagate = Set{SeaPearl.Constraint}([constraint])
        prunedDomains = SeaPearl.CPModification()
        res = SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
            
        @test !(constraint in toPropagate)

        SeaPearl.remove!(z.domain, 1)
        SeaPearl.addToPrunedDomains!(prunedDomains, z, [1])

        table = SeaPearl.cleanNegativeTable(vec,table)
        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 1

        @test !(0 in x.domain)
        @test !(0 in y.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "x"  => [0],
            "y"  => [0],
            "z" => [1],
        )
        
    end

end

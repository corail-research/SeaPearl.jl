@testset "compactshorttable.jl" begin
    @testset "cleanShortTable(variables::Vector{<:AbstractIntVar}, table::Matrix{Any})::Matrix{Any}" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = Vector{SeaPearl.AbstractIntVar}([x, y, z])
        table = [
            1 "*" 3 1;
            3 3 2 "*";
            1 2 3 1
        ]
        res = SeaPearl.cleanShortTable(vec, table)
        println()
        @test all(res .== ["*" 3; 3 2; 2 3])
    end
    @testset "buildShortSupport(variables::Vector{<:AbstractIntVar}, table::Matrix{Any})::Dict{Pair{Int,Int},BitVector}" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = Vector{SeaPearl.AbstractIntVar}([x, y, z])
        table = [
            1 "*" 3 1;
            3 3 2 "*";
            1 2 3 1
        ]
        table = SeaPearl.cleanShortTable(vec, table)
        support = SeaPearl.buildShortSupport(vec, table)
        supportStar = SeaPearl.buildShortSupportStar(vec, table)

        @test support[1 => 3] == [1,1]
        @test supportStar[1 => 3] == [0,1]

        @test support[3 => 2] == [1,0]
        @test supportStar[3 => 2] == [1,0]
    end
    @testset "cleanShortSupports!(supports::Dict{Pair{Int,Int},BitVector})::Nothing" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = Vector{SeaPearl.AbstractIntVar}([x, y, z])
        table = [
            1 "*" 3 1;
            3 3 2 "*";
            1 2 3 1
        ]
        table = SeaPearl.cleanShortTable(vec, table)
        support = SeaPearl.buildShortSupport(vec,table)
        supportStar = SeaPearl.buildShortSupportStar(vec,table)

        @test(all([(i => j) in keys(support) for i = 1:3, j = 2:3]))
        @test((1 => 1) in keys(support))
        @test((1 => 1) in keys(supportStar))

        SeaPearl.cleanShortSupports!(support)
        SeaPearl.cleanShortSupports!(supportStar)

        @test(((1 => 1) in keys(support)))
        @test(!((1 => 1) in keys(supportStar)))

        @test length(keys(support)) == 7

    end
    @testset "ShortTableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Any}, supports::Dict{Pair{Int,Int},BitVector}, supportsStar::Dict{Pair{Int,Int},BitVector}, trailer)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 3, "y", trailer)
        z = SeaPearl.IntVar(1, 3, "Z", trailer)
        vec1 = [x, y, z]
        vec2 = [z, y, x]
        table = [
            1 "*" 3 1;
            3 3 2 "*";
            1 2 3 1
        ]
        supports = SeaPearl.buildShortSupport(vec1, table)
        SeaPearl.cleanShortSupports!(supports)
        supportsStar = SeaPearl.buildShortSupportStar(vec1, table)
        SeaPearl.cleanShortSupports!(supportsStar)

        table = SeaPearl.cleanShortTable(vec1, table)
        constraint1 = SeaPearl.ShortTableConstraint(vec1, table, supports, supportsStar, trailer)
        constraint2 = SeaPearl.ShortTableConstraint(vec2, table, supports, supportsStar, trailer)

        @test size(constraint1.table, 2)==4
        @test size(constraint2.table, 2)==4

        @test (constraint1.supports[3=>2] == [0,1,0,0])
        @test (constraint1.supportsStar[3=>2] == [0,1,0,0])

        @test (constraint2.supports[1=>3] == [0,1,1,0])
        @test (constraint2.supportsStar[1=>3] == [0,0,1,0])

        @test(isempty(constraint1.modifiedVariables))
        @test(isempty(constraint2.modifiedVariables))
        @test(constraint1.residues[3=>2]==1)
        @test(constraint2.residues[3=>2]==1)
    end
    @testset "ShortTableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Any}, trailer)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = [x, y, z]
        table = [
            1 "*" 3 1;
            3 3 2 "*";
            1 2 3 1
        ]
        constraint = SeaPearl.ShortTableConstraint(vec, table, trailer)
        @test size(constraint.table, 2)==2
        @test (constraint.supports[3=>2] == [1,0])
        @test(isempty(constraint.modifiedVariables))
        @test(constraint.residues[3=>2]==1)
    end
    @testset "propagate!(constraint::ShortTableConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = [x, y, z]
        table = [
            1 "*" 3 1;
            3 3 3 "*";
            1 2 3 1
        ]

        table = SeaPearl.cleanShortTable(vec,table)

        constraint = SeaPearl.ShortTableConstraint(vec, table, trailer)

        toPropagate = Set{SeaPearl.Constraint}([constraint])
        prunedDomains = SeaPearl.CPModification()
        res = SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test !(constraint in toPropagate)

        @test length(x.domain) == 3
        @test length(y.domain) == 1
        @test length(z.domain) == 2
        @test 2 in x.domain
        @test 3 in y.domain
        @test 3 in z.domain

        SeaPearl.remove!(z.domain, 2)
        SeaPearl.addToPrunedDomains!(prunedDomains, z, [2])

        res = SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 1
        @test length(y.domain) == 1
        @test length(z.domain) == 1
        @test 3 in x.domain
        @test 3 in y.domain
        @test 3 in z.domain
    end

    
end

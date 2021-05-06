@testset "disjointSet.jl" begin
    @testset "union(disjointSet::DisjointSet, representative1::Int, representative2::Int)" begin  
        disjointSet = SeaPearl.DisjointSet(5)
        SeaPearl.union!(disjointSet, 2, 3)
        @test disjointSet.parent[2] == 3
        @test disjointSet.parent[3] == -2

        SeaPearl.union!(disjointSet, 3, 1)
        @test disjointSet.parent[3] == -2
        @test disjointSet.parent[1] == 3

        SeaPearl.union!(disjointSet, 4, 5)
        @test disjointSet.parent[4] == 5
        @test disjointSet.parent[5] == -2

        SeaPearl.union!(disjointSet, 5, 3)
        @test disjointSet.parent[1] == 3
        @test disjointSet.parent[2] == 3
        @test disjointSet.parent[3] == -3
        @test disjointSet.parent[4] == 5
        @test disjointSet.parent[5] == 3
    end

    @testset "find_representative(disjointSet::DisjointSet, element)::Int" begin  
        disjointSet = SeaPearl.DisjointSet(6)
        SeaPearl.union!(disjointSet, 3, 4)
        @test disjointSet.parent[3] == 4
        @test disjointSet.parent[4] == -2

        SeaPearl.union!(disjointSet, 5, 6)
        @test disjointSet.parent[5] == 6
        @test disjointSet.parent[6] == -2

        SeaPearl.union!(disjointSet, 4, 6)
        @test disjointSet.parent[3] == 4
        @test disjointSet.parent[4] == 6
        @test disjointSet.parent[5] == 6
        @test disjointSet.parent[6] == -3

        representative = SeaPearl.findRepresentative!(disjointSet, 3)
        @test representative == 6
        @test disjointSet.parent[3] == 6

        representative = SeaPearl.findRepresentative!(disjointSet, 1)
        @test representative == 1
    end


    @testset "greatest!(disjointSet::DisjointSet, element::Int)::Int" begin  
        disjointSet = SeaPearl.DisjointSet(6)
        SeaPearl.union!(disjointSet, 3, 4)
        SeaPearl.union!(disjointSet, 5, 6)
        SeaPearl.union!(disjointSet, 4, 6)

        max = SeaPearl.greatest!(disjointSet, 1)
        @test max == 1

        max = SeaPearl.greatest!(disjointSet, 3)
        @test max == 6
        @test disjointSet.parent[3] == 6
    end

    @testset "smallest!(disjointSet::DisjointSet, element::Int)::Int" begin  
        disjointSet = SeaPearl.DisjointSet(6)
        SeaPearl.union!(disjointSet, 3, 4)
        SeaPearl.union!(disjointSet, 5, 6)
        SeaPearl.union!(disjointSet, 4, 6)

        min = SeaPearl.smallest!(disjointSet, 1)
        @test min == 1

        min = SeaPearl.smallest!(disjointSet, 3)
        @test min == 3
        @test disjointSet.parent[3] == 6
    end
end
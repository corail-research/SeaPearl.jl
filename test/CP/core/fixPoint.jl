@testset "fixPoint.jl" begin
    @testset "fixPoint!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(5, 8, "y", trailer)
        z = SeaPearl.IntVar(6, 15, "z", trailer)
        t = SeaPearl.IntVar(6, 10, "t", trailer)
        u = SeaPearl.IntVar(10, 25, "u", trailer)

        constraint = SeaPearl.Equal(x, y, trailer)
        
        constraint3 = SeaPearl.Equal(z, t, trailer)

        model = SeaPearl.CPModel(trailer)

        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z)
        SeaPearl.addVariable!(model, t)
        SeaPearl.addVariable!(model, u)

        SeaPearl.addConstraint!(model, constraint)
        SeaPearl.addConstraint!(model, constraint3)
        feasability, prunedDomains = SeaPearl.fixPoint!(model)
        
        rightPruning = SeaPearl.CPModification("x" => [2, 3, 4],"z" => [11, 12, 13, 14, 15],"y" => [7, 8])

        @test prunedDomains == rightPruning
        @test feasability
        @test sum(map(x-> length(x[2]),collect(rightPruning))) == 10
        @test sum(map(x-> length(x[2]),collect(prunedDomains))) == 10

        @test length(x.domain) == 2
        @test length(y.domain) == 2
        @test length(z.domain) == 5
        @test length(t.domain) == 5

        constraint2 = SeaPearl.Equal(y, z, trailer)
        SeaPearl.addConstraint!(model, constraint2)

        SeaPearl.fixPoint!(model, Array{SeaPearl.Constraint}([constraint2]))


        @test SeaPearl.isbound(x)
        @test SeaPearl.isbound(y)
        @test SeaPearl.isbound(z)
        @test SeaPearl.isbound(t)

        constraint4 = SeaPearl.Equal(u, z, trailer)
        SeaPearl.addConstraint!(model, constraint4)

        feasability2, pruned = SeaPearl.fixPoint!(model, Array{SeaPearl.Constraint}([constraint4]))
        @test !feasability2
    end

    @testset "activity and impact update" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 4, "x", trailer)
        y = SeaPearl.IntVar(1, 4, "y", trailer)
        z = SeaPearl.IntVar(1, 4, "z", trailer)

        constraint1 = SeaPearl.Equal(x, y, trailer)
        constraint2 = SeaPearl.NotEqual(y, z, trailer)

        model = SeaPearl.CPModel(trailer)

        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z)
        SeaPearl.addConstraint!(model, constraint1)
        SeaPearl.addConstraint!(model, constraint2)

        feasability, prunedDomains = SeaPearl.fixPoint!(model)
        SeaPearl.saveState!(model.trailer)

        SeaPearl.assign!(x, 1)
        model.statistics.lastVar = x
        model.statistics.lastVal = 1 
        feasability, prunedDomains = SeaPearl.fixPoint!(model)

        @test model.activity_var_val[(x,1)] == 3 #x,y,z prunned
        @test model.impact_var_val[(x,1)] == 0.953125 #x and y prunned

        SeaPearl.assign!(z, 2)
        model.statistics.lastVar = z
        model.statistics.lastVal = 2
        feasability, prunedDomains = SeaPearl.fixPoint!(model)

        @test model.activity_var_val[(z,2)] == 1 #z prunned
        @test model.impact_var_val[(z,2)] == 0.6666667f0 #z prunned

        SeaPearl.restoreState!(model.trailer)

        SeaPearl.assign!(z, 2)
        model.statistics.lastVar = z
        model.statistics.lastVal = 2
        feasability, prunedDomains = SeaPearl.fixPoint!(model)

        @test model.activity_var_val[(z,2)] == 1.8f0 #x and y prunned
        @test model.impact_var_val[(z,2)] == 0.74375004f0 #x and y prunned

    end
end

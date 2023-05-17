@testset "objective_parser.jl" begin
    @testset "objective_simple" begin
        filename = "./parser/objective/data/objective_simple.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)                    

        @test isa(model.objective, SeaPearl.IntVar)
        @test model.objective == model.variables["z"]

    end

    @testset "objective_sum" begin
        filename = "./parser/objective/data/objective_sum.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)                    

        @test model.objective.id == "objective_1"
        @test isa(model.objective, SeaPearl.IntVar)
        @test maximum(model.objective.domain) == 7

        @test length(model.constraints) == 1
        @test isa(model.constraints[1], SeaPearl.SumToZero)
        for i = 1:length(dict_var["x"])
            @test isa(model.constraints[1].x[i],  SeaPearl.IntVarViewMul)
        end
    end

    @testset "objective_nValues" begin
        filename = "./parser/objective/data/objective_nValues.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)

        @test model.objective.id == "x_nValues"
        @test isa(model.objective, SeaPearl.IntVar)
        @test maximum(model.objective.domain) == 36

        @test length(model.constraints) == 1
        @test isa(model.constraints[1], SeaPearl.NValuesConstraint)
        @test length(model.constraints[1].x) == 200
    end

    @testset "objective_minimum" begin
        filename = "./parser/objective/data/objective_minimum.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)

        @test isa(model.objective, SeaPearl.IntVar)
        @test maximum(model.objective.domain) == 35
        @test minimum(model.objective.domain) == 0

        @test length(model.constraints) == 1
        @test isa(model.constraints[1], SeaPearl.MinimumConstraint)
        @test length(model.constraints[1].x) == 200
    end

    @testset "objective_maximum" begin
        filename = "./parser/objective/data/objective_maximum.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)

        @test isa(model.objective, SeaPearl.IntVar)
        @test maximum(model.objective.domain) == 35
        @test minimum(model.objective.domain) == 0

        @test length(model.constraints) == 1
        @test isa(model.constraints[1], SeaPearl.MaximumConstraint)
        @test length(model.constraints[1].x) == 200
    end
end

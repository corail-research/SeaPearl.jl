@testset "intension_parser.jl" begin
    @testset "intension_classic" begin
        filename = "./parser/constraints/data/intension/intension.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)                    

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 15
        @test isa(model.constraints[2], SeaPearl.Multiplication)
        @test length(model.constraints[1].x) == 3
    end

    @testset "intension_group" begin
        filename = "./parser/constraints/data/intension/intension_group.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 4
        @test isa(model.constraints[3], SeaPearl.SumToZero)

        # Test whether the number of variables in the intension constraint matches the model variable
        @test model.constraints[1].x[2] == model.variables["x[0]"]

        # Test whether the domains of the variables in the intension constraint match the domains specified in the XML file
        @test SeaPearl.maximum(model.constraints[4].x.domain) == 35
    end

    @testset "intension_constant" begin
        filename = "./parser/constraints/data/intension/intension_constant.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)                    

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 7
        @test isa(model.constraints[2], SeaPearl.GreaterOrEqual)
        @test isa(model.constraints[1].x, SeaPearl.IntVarViewMul)
    end
end

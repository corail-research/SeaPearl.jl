@testset "element_parser.jl" begin
    @testset "element constraint with array of Int" begin
        filename = "./parser/constraints/data/element/element_array_int.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)                    

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 1
        @test isa(model.constraints[1], SeaPearl.Element2D)
        @test length(model.constraints[1].matrix) == 5
    end

    @testset "element constraint with array of IntVar" begin
        filename = "./parser/constraints/data/element/element_array_intvar.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)                    

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 5
        @test isa(model.constraints[1], SeaPearl.Element1DVar)
        @test length(model.constraints[1].array) == 4
    end

end
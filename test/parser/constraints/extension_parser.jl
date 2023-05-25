@testset "extension_parser.jl" begin
    @testset "parse_support" begin
        str_support = "(1,4,8,0)(2,9,0,4)"
        table = SeaPearl.parse_support(str_support)
        @test size(table) == (4,2)

        str_support = "1 4..9 17"
        table = SeaPearl.parse_support(str_support)
        @test size(table) == (1,8)
    end
    
    @testset "extension_negative" begin
        filename = "./parser/constraints/data/extension/negative_table.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)      

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 16
        @test isa(model.constraints[1], SeaPearl.NegativeTableConstraint)
        @test length(model.constraints[1].scope) == 2
    end

    @testset "extension_positive" begin
        filename = "./parser/constraints/data/extension/positive_table.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)   

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 4
        @test isa(model.constraints[1], SeaPearl.TableConstraint)
        @test length(model.constraints[1].scope) == 5
    end
    @testset "extension_short_table" begin
        filename = "./parser/constraints/data/extension/short_table.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)     

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 5
        @test isa(model.constraints[1], SeaPearl.ShortTableConstraint)
        @test length(model.constraints[1].scope) == 3
    end
end

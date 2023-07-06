@testset "sum_parser.jl" begin
    @testset "sum_to_constant_constraint" begin
        filename = "./parser/constraints/data/sum/sum_to_constant.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)                    

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 7
        @test isa(model.constraints[1], SeaPearl.SumToConstant)
        @test length(model.constraints[1].x) == 4
    end

    @testset "sum_to_variable_constraint" begin
        filename = "./parser/constraints/data/sum/sum_to_variable.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)                    

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 7
        @test isa(model.constraints[1], SeaPearl.SumToZero)
        @test length(model.constraints[1].x) == 5
    end

    @testset "sum_group_constraint" begin
        filename = "./parser/constraints/data/sum/sum_group.xml"

        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 5
        @test isa(model.constraints[1], SeaPearl.SumLessThan)
        
        # Test whether the number of variables in the AllDifferent constraint matches the total number of variables in the arrays
        @test length(model.constraints[4].x) == 17
        
        # Test whether the variables in the AllDifferent constraint match the variables in the arrays
        @test all([var in model.constraints[3].x for var in dict_var["x"]])
        @test all([var in model.constraints[3].x for var in dict_var["y"]])
        
        # Test whether the domains of the variables in the AllDifferent constraint match the domains specified in the XML file
        for var in model.constraints[1].x
            @test SeaPearl.minimum(var.domain) == -1
            @test SeaPearl.maximum(var.domain) == 1
        end
    end

    @testset "sum_coeff" begin
        filename = "./parser/constraints/data/sum/sum_coeff.xml"
    
        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)
    
        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 24
        @test isa(model.constraints[1], SeaPearl.Multiplication)
        
        # Test whether the number of variables in sum constraint matches the total number of variables in the arrays
        @test length(model.constraints[end].x) == 21
        
        # Test whether the domains of the variables in the AllDifferent constraint match the domains specified in the XML file
        for var in model.constraints[18].x[1:end-1]
            @test SeaPearl.minimum(var.domain) == -1
            @test SeaPearl.maximum(var.domain) == 1
        end
    end
end

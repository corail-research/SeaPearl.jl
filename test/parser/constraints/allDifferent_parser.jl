using XML


@testset "allDifferent_parser.jl" begin
    @testset "allDifferent_group_constraint" begin
        filename = "./parser/constraints/data/allDifferent/allDifferent_group.xml"

        doc = XML.read(filename, XML.Node)
        instance = SeaPearl.find_element(doc, "instance")
        variables = SeaPearl.find_element(instance, "variables")
        constraints = SeaPearl.find_element(instance, "constraints")

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        dict_var = Dict{String,Any}()
        for var in XML.children(variables)
            id = attributes(var)["id"]
            if var.tag == "array"
                dict_var[id] = SeaPearl.parse_array_variable(var, model, trailer)
            end
        end
                    
        SeaPearl.parse_all_constraints(constraints, dict_var, model, trailer)                    

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 13
        @test isa(model.constraints[1], SeaPearl.AllDifferent)
        @test length(model.constraints[1].x) == 14
    end

    @testset "allDifferent_arrays" begin
        filename = "./parser/constraints/data/allDifferent/allDifferent_arrays.xml"

        doc = XML.read(filename, XML.Node)
        instance = SeaPearl.find_element(doc, "instance")
        variables = SeaPearl.find_element(instance, "variables")
        constraints = SeaPearl.find_element(instance, "constraints")

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        dict_var = Dict{String,Any}()
        for var in XML.children(variables)
            id = attributes(var)["id"]
            if var.tag == "array"
                dict_var[id] = SeaPearl.parse_array_variable(var, model, trailer)
            end
        end

        # Parse constraints
        SeaPearl.parse_all_constraints(constraints, dict_var, model, trailer)

        # Test whether the constraints have been correctly added to the model
        @test length(model.constraints) == 1
        @test isa(model.constraints[1], SeaPearl.AllDifferent)
        
        # Test whether the number of variables in the AllDifferent constraint matches the total number of variables in the arrays
        @test length(model.constraints[1].x) == length(dict_var["x"]) + length(dict_var["y"])
        
        # Test whether the variables in the AllDifferent constraint match the variables in the arrays
        @test all([var in model.constraints[1].x for var in dict_var["x"]])
        @test all([var in model.constraints[1].x for var in dict_var["y"]])
        
        # Test whether the domains of the variables in the AllDifferent constraint match the domains specified in the XML file
        for var in model.constraints[1].x
            @test SeaPearl.minimum(var.domain) == 0
            @test SeaPearl.maximum(var.domain) == 10
        end
    end
end

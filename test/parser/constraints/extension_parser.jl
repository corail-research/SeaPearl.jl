using XML


@testset "extension_parser.jl" begin
    @testset "extension_negative" begin
        filename = "./parser/constraints/data/extension/negative_table.xml"

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
        println(model.constraints[1].conflicts)
        @test model.constraints[1].conflicts
        @test length(model.constraints) == 16
        @test isa(model.constraints[1], SeaPearl.NegativeTableConstraint)
        @test length(model.constraints[1].scope) == 2
    end

    @testset "extension_positive" begin
        filename = "./parser/constraints/data/extension/positive_table.xml"

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
        @test length(model.constraints) == 4
        @test isa(model.constraints[1], SeaPearl.TableConstraint)
        @test length(model.constraints[1].scope) == 5
    end
    @testset "extension_short_table" begin
        filename = "./parser/constraints/data/extension/short_table.xml"

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
        @test length(model.constraints) == 5
        @test isa(model.constraints[1], SeaPearl.ShortTableConstraint)
        @test length(model.constraints[1].scope) == 3
    end
end

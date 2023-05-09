using XML 

@testset "variables_parser.jl" begin
    @testset "variable_1darray" begin
        filename = "./parser/variables/data/test_variable_1darray.xml"
        # Setup: parse trivial XML file containing Int variables in the range 1-35
        file = open(filename)
        xml_string = read(file, String)
        close(file)
        doc = parse(xml_string)
        instance = SeaPearl.find_element(doc, "instance")
        println(instance)
        variables = SeaPearl.find_element(instance, "variables")
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        dict_var = Dict{String,Any}()
        for var in XML.children(variables)
            id = attributes(var)["id"]
            if var.tag == "array"
                dict_var[id] = SeaPearl.parse_array_variable(var, model, trailer)
            end
        end
        # Test: check that the variables are correctly parsed
        var_names = []
        for i in 0:34
            push!(var_names, "x[$i]")
        end
        var_names = Set(var_names)
        target_domain_values = collect(1:35)
        @test length(model.variables) == 35
        @test model.variables["x[1]"].domain.values == target_domain_values
        for (var_name, var) in model.variables
            @test var_name in var_names
            pop!(var_names, var_name)
        end
    end
    @testset "variable_2darray" begin
        filename = "./parser/variables/data/test_variable_2darray.xml"
        # Setup: parse trivial XML file containing Int variables in the range 1-35
        file = open(filename)
        xml_string = read(file, String)
        close(file)
        doc = parse(xml_string)
        instance = SeaPearl.find_element(doc, "instance")
        variables = SeaPearl.find_element(instance, "variables")
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        dict_var = Dict{String,Any}()
        for var in XML.children(variables)
            id = attributes(var)["id"]
            if var.tag == "array"
                dict_var[id] = SeaPearl.parse_array_variable(var, model, trailer)
            end
        end
        # Test: check that the variables are correctly parsed
        var_names = []
        for i in 0:3
            for j in 0:4
                push!(var_names, "x[$i][$j]")
            end
        end
        var_names = Set(var_names)
        target_domain_values = collect(0:25)
        for target in target_domain_values
            @test target in model.variables["x[0][0]"].domain
        end
        @test length(model.variables) == 20
        @test SeaPearl.minimum(model.variables["x[0][0]"].domain) == 0
        @test SeaPearl.maximum(model.variables["x[0][0]"].domain) == 25
    end
    @testset "variable_array_different_domains" begin
        filename = "./parser/variables/data/test_variable_4darray.xml"
        # Setup: parse trivial XML file containing Int variables in the range 1-35
        file = open(filename)
        xml_string = read(file, String)
        close(file)
        doc = parse(xml_string)
        instance = SeaPearl.find_element(doc, "instance")
        variables = SeaPearl.find_element(instance, "variables")
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        dict_var = Dict{String,Any}()
        for var in XML.children(variables)
            id = attributes(var)["id"]
            if var.tag == "array"
                dict_var[id] = SeaPearl.parse_array_variable(var, model, trailer)
            end
        end
        
        @test length(model.variables) == 122

        @test SeaPearl.minimum(model.variables["x[0][0][0][0]"].domain) == 0
        @test SeaPearl.maximum(model.variables["x[0][0][0][0]"].domain) == 1
        @test SeaPearl.length(model.variables["x[0][0][0][0]"].domain) == 2

        @test SeaPearl.minimum(model.variables["y[1]"].domain) == -1
        @test SeaPearl.maximum(model.variables["y[1]"].domain) == 1
        @test SeaPearl.length(model.variables["y[1]"].domain) == 2
    end
end
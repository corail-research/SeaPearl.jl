@testset "variables_parser.jl" begin
    @testset "variable_array" begin
        filename = "./parser/variables/data/test_variable_array.xml"
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
end
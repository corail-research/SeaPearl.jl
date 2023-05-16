using XML

@testset "variables_parser.jl" begin

    @testset "variable_1darray" begin
        filename = "./parser/variables/data/test_variable_1darray.xml"
        # Setup: parse trivial XML file containing Int variables in the range 1-35
        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)

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
        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)

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

    @testset "variable_4darray" begin
        filename = "./parser/variables/data/test_variable_4darray.xml"

        # Setup: parse trivial XML file containing Int variables in the range 1-35
        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)

        @test length(model.variables) == 122

        @test SeaPearl.minimum(model.variables["x[0][0][0][0]"].domain) == 0
        @test SeaPearl.maximum(model.variables["x[0][0][0][0]"].domain) == 1
        @test SeaPearl.length(model.variables["x[0][0][0][0]"].domain) == 2

        @test SeaPearl.minimum(model.variables["y[1]"].domain) == -1
        @test SeaPearl.maximum(model.variables["y[1]"].domain) == 1
        @test SeaPearl.length(model.variables["y[1]"].domain) == 2
    end

    @testset "variable_array_different_domain" begin
        filename = "./parser/variables/data/test_variable_array_different_domains.xml"

        # Setup: parse trivial XML file containing Int variables in the range 1-35
        model, trailer, dict_var = SeaPearl.parse_xml_file(filename)

        @test length(model.variables) == 19

        @test size(dict_var["pr"]) == (4,4)

        @test model.variables["pr[0][2]"] == dict_var["pr"][1,3]

        @test SeaPearl.minimum(model.variables["pr[0][2]"].domain) == -1
        @test SeaPearl.maximum(model.variables["pr[0][0]"].domain) == 1
        @test SeaPearl.length(model.variables["pr[0][0]"].domain) == 2

        @test SeaPearl.maximum(model.variables["e[0]"].domain) == 26
        @test SeaPearl.maximum(model.variables["e[2]"].domain) == 60

    end

end
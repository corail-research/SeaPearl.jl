@testset "group_parser.jl" begin

    @testset "get_all_str_variables" begin 
        dimensions = [6, 9, 11]
        str_variables = "x[0][][3..7]"
        str_variables_vector = SeaPearl.get_all_str_variables(str_variables, dimensions)
        @test length(str_variables_vector) == 45

        str_variables = "x[2..4][4][5..10]"
        str_variables_vector = SeaPearl.get_all_str_variables(str_variables, dimensions)
        @test length(str_variables_vector) == 18

        str_variables = "x[][][4..9]"
        str_variables_vector = SeaPearl.get_all_str_variables(str_variables, dimensions)
        @test length(str_variables_vector) == 324
    end

    @testset "fill_pattern!" begin
        filename = "./parser/constraints/data/group/fill_pattern.xml"

        doc = XML.read(filename, XML.Node)

        instance = SeaPearl.find_element(doc, "instance")
        variables = SeaPearl.find_element(instance, "variables")

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        dict_variables = SeaPearl.parse_all_variables(variables, model, trailer)

        constraint_variables_nodes = SeaPearl.find_element(instance, "constraints")
        str_constraints = [
        "eq(sub(x[0][1][12],x[1][0][10]),x[2][0][9])", 
        "eq(sub(x[1][0][12],x[1][1][12]),x[5][9][1])",
        "eq(sub(x[1][1][12],x[2][1][12]),x[3][1][12])"
        ]

        pattern = "eq(sub(%0,%1),%2)"
        for (i,constraint_variables) in enumerate(constraint_variables_nodes.children)
            str_constraint = SeaPearl.fill_pattern!(pattern, constraint_variables, dict_variables)
            @test str_constraint == str_constraints[i]
        end
    end


end

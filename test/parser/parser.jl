using XML

@testset "parser.jl" begin
    include("constraints/constraints.jl")
    include("variables/variables_parser.jl")
    include("objective/objective_parser.jl")
end
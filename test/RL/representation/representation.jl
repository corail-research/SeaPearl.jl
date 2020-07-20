struct UnimplementedFeaturization <: CPRL.AbstractFeaturization end
struct UnimplementFeatState{F} <: CPRL.FeaturizedStateRepresentation{F} end



@testset "representation.jl" begin

    @testset "Unimplemented featurization" begin
        @test_throws ErrorException CPRL.featurize(UnimplementFeatState{UnimplementedFeaturization}())
    end

    include("default/cp_layer/cp_layer.jl")
    include("default/defaultstaterepresentation.jl")

end
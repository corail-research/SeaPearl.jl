struct UnimplementedFeaturization <: SeaPearl.AbstractFeaturization end
struct TestFeatState{F} <: SeaPearl.FeaturizedStateRepresentation{F} end

struct TestFeaturization <: SeaPearl.AbstractFeaturization end

function SeaPearl.featurize(::TestFeatState{TestFeaturization})
    return [1, 2, 3]
end

@testset "representation.jl" begin

    include("default/cp_layer/cp_layer.jl")
    include("default/defaultstaterepresentation.jl")

    @testset "Unimplemented featurization" begin
        @test_throws ErrorException SeaPearl.featurize(TestFeatState{UnimplementedFeaturization}())
    end

    @testset "Custom featurization" begin
        @test SeaPearl.featurize(TestFeatState{TestFeaturization}()) == [1, 2, 3]
    end

end
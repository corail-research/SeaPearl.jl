struct UnimplementedFeaturization <: CPRL.AbstractFeaturization end
struct TestFeatState{F} <: CPRL.FeaturizedStateRepresentation{F} end

struct TestFeaturization <: CPRL.AbstractFeaturization end

function CPRL.featurize(::TestFeatState{TestFeaturization})
    return [1, 2, 3]
end

@testset "representation.jl" begin

    include("default/cp_layer/cp_layer.jl")
    include("default/defaultstaterepresentation.jl")

    @testset "Unimplemented featurization" begin
        @test_throws ErrorException CPRL.featurize(TestFeatState{UnimplementedFeaturization}())
    end

    @testset "Custom featurization" begin
        @test CPRL.featurize(TestFeatState{TestFeaturization}()) == [1, 2, 3]
    end

end
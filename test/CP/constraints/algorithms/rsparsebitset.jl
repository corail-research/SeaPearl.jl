@testset "RSparseBitSet" begin
    @testset "RSparseBitSet(size, trailer)" begin
        trailer = SeaPearl.Trailer()
        n = 540

        sets = [
            SeaPearl.RSparseBitSet{UInt8}(n, trailer)
            SeaPearl.RSparseBitSet{UInt16}(n, trailer)
            SeaPearl.RSparseBitSet{UInt32}(n, trailer)
            SeaPearl.RSparseBitSet{UInt64}(n, trailer)
            SeaPearl.RSparseBitSet{UInt128}(n, trailer)
        ]

        strings = [join([bitstring(word.value) for word in set.words]) for set in sets]
        bools = [occursin(Regex("^1{$(n)}0*\$"), str) for str in strings]
        @test all(bools)
        @test all([set.limit.value == length(set.words) for set in sets])
    end

    @testset "Base.getindex" begin
        trailer = SeaPearl.Trailer()
        n = 540

        set = SeaPearl.RSparseBitSet(n, trailer)
        for word in set.words
            SeaPearl.setValue!(word, UInt64(0))
        end
        SeaPearl.setValue!(set.words[2], UInt64(1) << 63 | UInt64(1))
        
        @test !any([set[i] for i in 1:64])
        @test set[65]
        @test !any([set[i] for i in 66:127])
        @test set[128]
    end

    @testset "clearMask!" begin
        trailer = SeaPearl.Trailer()
        n = 540

        set = SeaPearl.RSparseBitSet(n, trailer)
        set.mask .= typemax(UInt64)
        SeaPearl.setValue!(set.limit, 6)

        SeaPearl.clearMask!(set)
        @test all(set.mask[1:6] .== UInt64(0))
        @test all(set.mask[7:end] .== typemax(UInt64))
    end

    @testset "reverseMask!" begin
        trailer = SeaPearl.Trailer()
        n = 540

        set = SeaPearl.RSparseBitSet(n, trailer)
        SeaPearl.clearMask!(set)
        set.mask[1:3] .= typemax(UInt64)
        SeaPearl.setValue!(set.limit, 6)

        SeaPearl.reverseMask!(set)
        @test all(set.mask[1:3] .== UInt64(0))
        @test all(set.mask[4:6] .== typemax(UInt64))
        @test all(set.mask[7:end] .== UInt64(0))
    end

    @testset "addToMask!" begin
        trailer = SeaPearl.Trailer()
        n = 20
        
        set = SeaPearl.RSparseBitSet{UInt8}(n, trailer)
        SeaPearl.clearMask!(set)
        x = [
            UInt8(1) << 7 | UInt8(1) << 2, 
            UInt8(1) << 4,
            UInt8(1)
        ]
        y = [
            UInt8(1) << 3, 
            UInt8(1) << 4,
            UInt8(1) << 2
        ]

        SeaPearl.addToMask!(set, x)
        @test all(set.mask .== x)

        SeaPearl.addToMask!(set, y)
        @test all(set.mask .== x .| y)
    end

    @testset "intersectWithMask!" begin
        trailer = SeaPearl.Trailer()
        n = 20
        
        set = SeaPearl.RSparseBitSet{UInt8}(n, trailer)
        SeaPearl.clearMask!(set)
        set.mask[1:end] = [
            UInt8(1) << 7 | UInt8(1) << 2, 
            UInt8(1) << 4,
            UInt8(1)
        ]
        
        SeaPearl.intersectWithMask!(set)
        @test set[1]
        @test set[6]
        @test set[12]
        @test !any([set[i] for i in setdiff(1:24, [1,6,12])])
    end

    @testset "intersectIndex" begin
        trailer = SeaPearl.Trailer()
        n = 20
        
        set = SeaPearl.RSparseBitSet{UInt8}(n, trailer)
        SeaPearl.clearMask!(set)
        set.mask[1:end] = [
            UInt8(1) << 7 | UInt8(1) << 2, 
            UInt8(1) << 4,
            UInt8(1) << 7
        ]
        SeaPearl.intersectWithMask!(set)

        x = [UInt8(1) << 2, typemax(UInt8), typemax(UInt8)]
        @test SeaPearl.intersectIndex(set, x) == 1
       
        y = [UInt8(1) << 3, UInt8(0), typemax(UInt8)]
        @test SeaPearl.intersectIndex(set, y) == 3

        z = [UInt8(1) << 3, UInt8(0), UInt8(0)]
        @test SeaPearl.intersectIndex(set, z) == -1

    end
end
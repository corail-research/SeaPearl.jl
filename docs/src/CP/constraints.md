# Constraints

```@docs
SeaPearl.Absolute
```

```@docs
SeaPearl.AllDifferent(x::Array{<:AbstractIntVar}, trailer)
```

```@docs
SeaPearl.BinaryEquivalence(x::AbstractBoolVar, y::AbstractBoolVar, trailer)
```

```@docs
SeaPearl.BinaryImplication(x::AbstractBoolVar, y::AbstractBoolVar, trailer)
SeaPearl.BinaryMaximumBC(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)
SeaPearl.BinaryOr(x::AbstractBoolVar, y::AbstractBoolVar, trailer)
SeaPearl.BinaryXor(x::AbstractBoolVar, y::AbstractBoolVar, trailer)
SeaPearl.TableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Int}, supports::Dict{Pair{Int,Int},BitVector}, trailer::SeaPearl.Trailer)
SeaPearl.TableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Int}, trailer)
SeaPearl.BinaryImplication(x::AbstractBoolVar, y::AbstractBoolVar, trailer)
Disjunctive(earliestStartingTime::Array{<:AbstractIntVar}, 
                        processingTime::Array{Int}, trailer, filteringAlgorithm::Array{filteringAlgorithmTypes} = [algoTimeTabling])::Disjunctive
SeaPearl.Element1D(matrix::Array{Int, 1}, i::AbstractIntVar, x::AbstractIntVar, trailer::Trailer)
SeaPearl.Element2D(matrix::Array{Int, 2}, x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)
SeaPearl.EqualConstant(x::SeaPearl.AbstractIntVar, v::Int, trailer)
SeaPearl.GreaterOrEqualConstant(x::SeaPearl.AbstractIntVar, v::Int)
SeaPearl.InSet(x::AbstractIntVar, s::IntSetVar, trailer)
SeaPearl.IntervalConstant(x::SeaPearl.IntVar, lower::Int, upper::Int, trailer)
SeaPearl.isBinaryAnd(b::AbstractBoolVar, x::AbstractBoolVar, y::AbstractBoolVar, trailer)
SeaPearl.isBinaryOr(b::AbstractBoolVar, x::AbstractBoolVar, y::AbstractBoolVar, trailer)
SeaPearl.isBinaryXor(b::AbstractBoolVar, x::AbstractBoolVar, y::AbstractBoolVar, trailer)
SeaPearl.isLessOrEqual(b::AbstractBoolVar, x::AbstractIntVar, y::AbstractIntVar, trailer)
SeaPearl.LessOrEqualConstant(x::AbstractIntVar, v::Int, trailer)
SeaPearl.LessOrEqual(x::AbstractIntVar, y::AbstractIntVar, trailer)
SeaPearl.MaximumConstraint(x::Array{<:AbstractIntVar},y::AbstractIntVar, trailer)
SeaPearl.NotEqualConstant(x::AbstractIntVar, v::Int, trailer)
SeaPearl.NotEqual(x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar, trailer::Trailer)
SeaPearl.ReifiedInSet(x::AbstractIntVar, s::IntSetVar, b::AbstractBoolVar, trailer::Trailer)
SeaPearl.SetDiffSingleton(a::IntSetVar, b::IntSetVar, x::AbstractIntVar, trailer)
SeaPearl.SetEqualConstant(s::IntSetVar, c::Set{Int}, trailer)
SeaPearl.SumGreaterThan(x::Array{<:AbstractIntVar}, lower::Int, trailer)
SeaPearl.SumLessThan(x::Array{<:AbstractIntVar}, upper::Int,  trailer)
SeaPearl.SumToZero(x::Array{<:AbstractIntVar}, trailer)
```
# Constraints

```@docs
SeaPearl.Absolute
```

```@docs
SeaPearl.AllDifferent
```

```@docs
SeaPearl.BinaryEquivalence
```

```@docs
SeaPearl.BinaryImplication
SeaPearl.BinaryMaximumBC
SeaPearl.BinaryOr
SeaPearl.BinaryXor
SeaPearl.TableConstraint
<!-- SeaPearl.TableConstraint -->
SeaPearl.BinaryImplication
SeaPearl.Disjunctive(earliestStartingTime::Array{<:SeaPearl.AbstractIntVar}, processingTime::Array{Int}, trailer, filteringAlgorithm::Array{filteringAlgorithmTypes} = [algoTimeTabling])
SeaPearl.Element1D(matrix::Array{Int, 1}, i::SeaPearl.AbstractIntVar, x::SeaPearl.AbstractIntVar, trailer::SeaPearl.Trailer)
SeaPearl.Element2D(matrix::Array{Int, 2}, x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar, z::SeaPearl.AbstractIntVar, trailer)
SeaPearl.EqualConstant(x::SeaPearl.SeaPearl.AbstractIntVar, v::Int, trailer)
SeaPearl.GreaterOrEqualConstant(x::SeaPearl.SeaPearl.AbstractIntVar, v::Int)
SeaPearl.InSet(x::SeaPearl.AbstractIntVar, s::SeaPearl.IntSetVar, trailer)
SeaPearl.IntervalConstant(x::SeaPearl.IntVar, lower::Int, upper::Int, trailer)
SeaPearl.isBinaryAnd(b::SeaPearl.AbstractBoolVar, x::SeaPearl.AbstractBoolVar, y::SeaPearl.AbstractBoolVar, trailer)
SeaPearl.isBinaryOr(b::SeaPearl.AbstractBoolVar, x::SeaPearl.AbstractBoolVar, y::SeaPearl.AbstractBoolVar, trailer)
SeaPearl.isBinaryXor(b::SeaPearl.AbstractBoolVar, x::SeaPearl.AbstractBoolVar, y::SeaPearl.AbstractBoolVar, trailer)
SeaPearl.isLessOrEqual(b::SeaPearl.AbstractBoolVar, x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar, trailer)
SeaPearl.LessOrEqualConstant(x::SeaPearl.AbstractIntVar, v::Int, trailer)
SeaPearl.LessOrEqual(x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar, trailer)
SeaPearl.MaximumConstraint(x::Array{<:SeaPearl.AbstractIntVar},y::SeaPearl.AbstractIntVar, trailer)
SeaPearl.NotEqualConstant(x::SeaPearl.AbstractIntVar, v::Int, trailer)
SeaPearl.NotEqual(x::SeaPearl.SeaPearl.AbstractIntVar, y::SeaPearl.SeaPearl.AbstractIntVar, trailer::SeaPearl.Trailer)
SeaPearl.ReifiedInSet(x::SeaPearl.AbstractIntVar, s::SeaPearl.IntSetVar, b::SeaPearl.AbstractBoolVar, trailer::SeaPearl.Trailer)
SeaPearl.SetDiffSingleton(a::SeaPearl.IntSetVar, b::SeaPearl.IntSetVar, x::SeaPearl.AbstractIntVar, trailer)
SeaPearl.SetEqualConstant(s::SeaPearl.IntSetVar, c::Set{Int}, trailer)
SeaPearl.SumGreaterThan(x::Array{<:SeaPearl.AbstractIntVar}, lower::Int, trailer)
SeaPearl.SumLessThan(x::Array{<:SeaPearl.AbstractIntVar}, upper::Int,  trailer)
SeaPearl.SumToZero(x::Array{<:SeaPearl.AbstractIntVar}, trailer)
```
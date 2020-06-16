# Variables

The implementation of variables in CPRL is heavily inspired on [MiniCP](https://minicp.readthedocs.io/en/latest/learning_minicp/part_2.html). If you have some troubles understanding how it works, you can get more visual explanations by reading their [slides](https://inginious.org/course/minicp/domains).

The variables are all a subset of `AbstractIntVar`.
```@docs
CPRL.AbstractIntVar
```

Every `AbstractIntVar` must have a unique `id` that you can retrieve with `id`.
```@docs
CPRL.id
CPRL.isbound
CPRL.assign!(::CPRL.AbstractIntVar, ::Int)
CPRL.assignedValue
```

## IntVar

```@docs
CPRL.IntVar
CPRL.IntVar(::Int, ::Int, ::String, ::CPRL.Trailer)
```

## IntDomain

```@docs
CPRL.AbstractIntDomain
CPRL.IntDomain
CPRL.IntDomain(::CPRL.Trailer, ::Int, ::Int)
CPRL.isempty
CPRL.length
CPRL.isempty
Base.in(::Int, ::CPRL.IntDomain)
CPRL.remove!
CPRL.removeAll!
CPRL.removeAbove!
CPRL.removeBelow!
CPRL.assign!
Base.iterate(::CPRL.IntDomain)
CPRL.updateMaxFromRemovedVal!
CPRL.updateMinFromRemovedVal!
CPRL.updateBoundsFromRemovedVal!
CPRL.minimum
CPRL.maximum
```

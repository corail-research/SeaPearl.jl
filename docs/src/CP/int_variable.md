# Variables

The implementation of variables in SeaPearl is heavily inspired on [MiniCP](https://minicp.readthedocs.io/en/latest/learning_minicp/part_2.html). If you have some troubles understanding how it works, you can get more visual explanations by reading their [slides](https://inginious.org/course/minicp/domains).

The variables are all a subset of `AbstractIntVar`.
```@docs
SeaPearl.AbstractIntVar
```

Every `AbstractIntVar` must have a unique `id` that you can retrieve with `id`.
```@docs
SeaPearl.id
SeaPearl.isbound
SeaPearl.assign!(::SeaPearl.AbstractIntVar, ::Int)
SeaPearl.assignedValue
```

## IntVar

```@docs
SeaPearl.IntVar
SeaPearl.IntVar(::Int, ::Int, ::String, ::SeaPearl.Trailer)
```

## IntDomain

```@docs
SeaPearl.AbstractIntDomain
SeaPearl.IntDomain
SeaPearl.IntDomain(::SeaPearl.Trailer, ::Int, ::Int)
SeaPearl.isempty
SeaPearl.length
SeaPearl.isempty
Base.in(::Int, ::SeaPearl.IntDomain)
SeaPearl.remove!
SeaPearl.removeAll!
SeaPearl.removeAbove!
SeaPearl.removeBelow!
SeaPearl.assign!
Base.iterate(::SeaPearl.IntDomain)
SeaPearl.updateMaxFromRemovedVal!
SeaPearl.updateMinFromRemovedVal!
SeaPearl.updateBoundsFromRemovedVal!
SeaPearl.minimum
SeaPearl.maximum
```

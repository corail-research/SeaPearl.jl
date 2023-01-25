# Variables

## Integer variables

The implementation of integer variables in SeaPearl is heavily inspired on [MiniCP](https://minicp.readthedocs.io/en/latest/learning_minicp/part_2.html). If you have some troubles understanding how it works, you can get more visual explanations by reading their [slides](https://inginious.org/course/minicp/domains).

The integer variables are all a subset of `AbstractIntVar`.


Every `AbstractIntVar` must have a unique `id` that you can retrieve with `id`.
```@docs
SeaPearl.id
SeaPearl.isbound
SeaPearl.assign!(::SeaPearl.AbstractIntVar, ::Int)
SeaPearl.assignedValue
```

### IntVar

```@docs
SeaPearl.IntVar
SeaPearl.IntVar(::Int, ::Int, ::String, ::SeaPearl.Trailer)
```

### IntDomain

```@docs
SeaPearl.AbstractIntDomain
SeaPearl.IntDomain
SeaPearl.IntDomain(::SeaPearl.Trailer, ::Int, ::Int)
```

### Domain updates
```@docs
SeaPearl.isempty
SeaPearl.length
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

If you want to express some variations of an integer variable ``x`` (for example ``-x`` or ``a x`` with ``a > 0``) in a constraint, you can use the `IntVarView` types:

### IntVarView

```@docs
SeaPearl.IntVarViewMul
SeaPearl.IntVarViewOpposite
SeaPearl.IntVarViewOffset
```

### IntDomainView
```@docs
SeaPearl.IntDomainViewMul
SeaPearl.IntDomainViewOpposite
SeaPearl.IntDomainViewOffset
```

## Boolean Variables

### Base Boolean Variables
```@docs
SeaPearl.BoolVar
```

### Boolean View Variables

```@docs
SeaPearl.BoolVarViewNot
```

### Boolean Domains
```@docs
SeaPearl.BoolDomain
SeaPearl.BoolDomainViewNot
```

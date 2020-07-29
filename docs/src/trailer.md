# Trailer: backtrack easily and efficiently

The trailer is the object that keeps track of anything you want to keep track of.
Some objects will take a `trailer` as a parameter in their constructor. When it does, it means that their state
can be saved and restored on demand using the functions described below.

## State manipulation

Those functions are used to change the current state, save and or restore it.

Note that during your "state exploration", you can only restore higher. It is not possible to restore some deeper state, or state that could be in the same level.
For example, if you have a state A at some point, you call [`SeaPearl.saveState!`](@ref) to store it.
You edit some [`SeaPearl.StateObject`](@ref), making you at some state B. Then you call [`SeaPearl.restoreState!`](@ref)
that will restore every [`SeaPearl.StateObject`](@ref) to the state A. At that point, there is no way to go back to the state B
using the trailer.

```@docs
SeaPearl.StateObject
SeaPearl.StateEntry
SeaPearl.trail!
SeaPearl.setValue!
SeaPearl.saveState!
SeaPearl.restoreState!
SeaPearl.withNewState!
SeaPearl.restoreInitialState!
```
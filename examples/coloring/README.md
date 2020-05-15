# Graph coloring example

This is inspired from the __Discrete optimization__ course of Coursera, you can visualize data and solution files using their [website](https://discreteoptimization.github.io/vis/coloring/).

To launch this example, you need to have the packages `DataStructures` and `CPRL` as dependencies.

Being inside that folder in the terminal (`examples/coloring/`), you can launch:

```julia
julia> include("coloring.jl")
julia> solve_coloring("data/gc_4_1")
```

This will print the solutions found and write the last solution to a file in the `solution/` folder.
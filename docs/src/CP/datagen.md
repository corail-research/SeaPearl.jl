# Data Generation

All model generation functions use the function `fill_with_generator!`, which takes as input a `CPModel`, an `AbstractModelGenerator` and optionally a random number generator.

## Graph Coloring
SeaPearl makes available many types of graphs for the grpah coloring problem:

```@docs
SeaPearl.fill_with_generator!
SeaPearl.HomogenousGraphColoringGenerator
SeaPearl.ClusterizedGraphColoringGenerator
SeaPearl.BarabasiAlbertGraphGenerator
SeaPearl.ErdosRenyiGraphGenerator
```

## Eternity 2
```@docs
SeaPearl.Eternity2Generator
```

## Jobshop

```@docs
SeaPearl.JobShopGenerator
SeaPearl.JobShopSoftDeadlinesGenerator2
```

## Kidney Exchange

```@docs
SeaPearl.KepGenerator
```
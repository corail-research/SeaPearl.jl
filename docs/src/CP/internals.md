# SeaPearl Internals

## CPModel

```@docs
SeaPearl.Statistics
SeaPearl.Limit
SeaPearl.CPModel
SeaPearl.addVariable!
SeaPearl.addObjective!
SeaPearl.addKnownObjective!
SeaPearl.addConstraint!
SeaPearl.is_branchable
SeaPearl.branchable_variables
SeaPearl.solutionFound
SeaPearl.triggerFoundSolution!
SeaPearl.triggerInfeasible!
SeaPearl.tightenObjective!
Base.isempty
Base.empty!
SeaPearl.reset_model!
SeaPearl.restart_search!
SeaPearl.domains_cartesian_product
SeaPearl.nb_boundvariables
SeaPearl.global_domain_cardinality
SeaPearl.updateStatistics!
```

## Search
```@docs
SeaPearl.initroot!
SeaPearl.dfs
SeaPearl.expandDfwbs!
SeaPearl.expandIlds!
SeaPearl.expandLns!
SeaPearl.expandRbs!
```
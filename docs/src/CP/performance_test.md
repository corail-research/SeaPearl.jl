# Performance test - Gecode vs SeaPearl

The objective is to compare the execution time between SeaPearl and a commercial CP Solver.

We expect SeaPearl to be less efficient for 2 reasons:
* Information is collected on each node in order to do further analysis (RL).
* Some constraints algorithms are not state-of-the-art algorithms.

## Method

The commercial CP solver used is Gecode and the model has been implemented using MiniZinc. 
The problem used for the experience is the Kidney Exchange Problem (KEP) using 7 instances from size 5 to 35 (step size of 5). 
A basic model has been implemented in MiniZinc and SeaPearl using the same logic (variables, constraints, heuristics...).

## Results and conclusions

The main observations from the experience are:

* The time of execution grows over-polynomially with the size of the instance. This result was expected for this combinatorial problem.
* For instances with significant time of execution (more than 1 second), **Gecode is on average 7.5 times faster than SeaPearl**.

### PS: Tips to do a performance test with SeaPearl

Some tips to implement a model in MiniZinc and SeaPearl with similar behavior:
* In MiniZinc use these arguments for the search: `first_fail`, `indomain_max`, `complete`.
* In SeaPearl use these arguments for the search: `MinDomainVariableSelection`, `BasicHeuristic`, `DFSearch` (by default).
* `first_fail` and `MinDomainVariableSelection` do not have the same behavior in the tie (many variables having the domain with the same minimum size). `first_fail` uses the input order for tie-breaker. Therefore, one option is to change `MinDomainVariableSelection` to have the same behavior (e.g. use a counter for the `id` of the variables and add a lexicographical tie-breaker in `MinDomainVariableSelection`).
* Check the number of explored nodes in both models. One should have similar values for each instance. One can check this information in SeaPearl thanks to `model.statistics.numberOfNodes` and in MiniZinc by checking the output solving statistics checkbox in the configuration editor menu.

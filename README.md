# SeaPearl.jl

SeaPearl is a Constraint Programming solver that can use Reinforcement Learning agents as value-selection heuristics, using graphs as inputs for the agent's approximator. It is to be seen as a tool for researchers that gives the possibility to go above and beyond what has already been done with it.

The paper accompanying this solver can be found on the [arXiv](https://arxiv.org/abs/2102.09193v1). If you use SeaPearl in your research, please cite our work.

The RL agents are defined using [ReinforcementLearning.jl](https://github.com/JuliaReinforcementLearning/ReinforcementLearning.jl), their inputs are dealt with using [GeometricFlux.jl](https://github.com/FluxML/GeometricFlux.jl) and [Flux.jl](https://github.com/FluxML/Flux.jl). The CP part, inspired from [MiniCP](http://www.minicp.org/), is focused on readability. The code is meant to be clear and modulable so that researchers could easily get access to CP data and use it as input for their ML model.

## Installation

```julia
]add SeaPearl
```

## Use

Working examples can be found in [SeaPearlZoo](https://github.com/corail-research/SeaPearlZoo).

SeaPearl can be use either as a classic CP solver that uses predefined variable and value selection heuristics or as Reinforcement Learning driven CP solver that is capable of learning trought solving automatically generated instances of a given problem ( knapsack, tsptw, graphcoloring, nurse rostering ...). 

### SeaPearl as a classic CP solver : 
To use SeaPearl as a classic CP solver, one needs to  : 
1. declare a variable selection heuristic : 
```julia
YourVariableSelectionHeuristic{TakeObjective} <: SeaPearl.AbstractVariableSelection{TakeObjective}
```
2. declare a value selection heuristic : 
```julia
BasicHeuristic <: ValueSelection
```
3. create a Constraint Programming Model : 
```julia
trailer = SeaPearl.Trailer()
model = SeaPearl.CPModel(trailer)

#create variable : 
SeaPearl.addVariable!(...)

#add constraints : 
SeaPearl.addConstraint!(model, SeaPearl.AbstractConstraint(...))

#add optionnal objective function : 
SeaPearl.addObjective!(model, ObjectiveVar)
```
### SeaPearl as a RL-driven CP solver : 
To use SeaPearl as a RL-driven CP solver, one needs to  : 
1. declare a variable selection heuristic : 
```julia
CustomVariableSelectionHeuristic{TakeObjective} <: SeaPearl.AbstractVariableSelection{TakeObjective}
```
2. declare a value selection learnedheuristic : 
```julia
LearnedHeuristic{SR<:AbstractStateRepresentation, R<:AbstractReward, A<:ActionOutput} <: ValueSelection
```
3. *optionnaly*, declare some classic value selection heuristic for benchmarking purposes
```julia
basicHeuristic = SeaPearl.BasicHeuristic((x; cpmodel) -> your_function(...))
```
4. define an agent : 
```julia
agent = RL.Agent(
policy=(...),
trajectory=(...),
)
```
5.  *optionnaly*, declare a custom reward : 
```julia
CustomReward <: SeaPearl.AbstractReward 
```
6.  *optionnaly*, declare a custom StateRepresentation ( instead of the Default tripartite-graph representation ) : 
```julia
CustomStateRepresentation <: SeaPearl.AbstractStateRepresentation
```
7.  *optionnaly*, declare a custom featurization for the StateRepresentation : 
```julia
CustomFeaturization <: SeaPearl.AbstractFeaturization
```
8.  create a generator for your given problem, that will create different instances of the specific problem used during the learning process. 
```julia
CustomProblemGenerator <: AbstractModelGenerator
```
9.  set a number of training epochs, declare an evaluator, a Strategy, a metric for benchmarking
```julia
nb_epochs = 3000
CustomStrategy <: SearchStrategy #or use predefined one : SeaPearl.DFSearch
CustomEvaluator <: AbstractEvaluator #or use predefined one : SeaPearl.SameInstancesEvaluator(...)
function CustomMetricsFun
```
9. launch the training :  
```julia
bestsolutions, nodeVisited,timeneeded, eval_nodevisited, eval_timeneeded = SeaPearl.train!(
valueSelectionArray=[learnedHeuristic, basicHeuristic], 
generator=CustomProblemGenerator,
nbEpisodes=nbEpisodes,
strategy=CustomStrategy,
variableHeuristic=CustomVariableSelectionHeuristic,
metricsFun=CustomMetricsFun,
evaluator=CustomEvaluator
```
)


## Contributing to SeaPearl

All PRs and issues are welcome.
This repo contains README.md and images to facilitate the understanding of the code. 
To contribute to Sealpearl, follow these steps:

1. Fork this repository.
2. Create a branch: `git checkout -b <branch_name>`.
3. Make your changes and commit them: `git commit -m '<commit_message>'`
4. Push to the original branch: `git push origin <project_name>/<location>`
5. Create the pull request.

Alternatively see the GitHub documentation on [creating a pull request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request).


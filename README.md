# SeaPearl.jl

SeaPearl is a Constraint Programming solver that can use Reinforcement Learning agents as value-selection heuristics, using graphs as inputs for the agent's approximator. It is to be seen as a tool for researchers that gives the possibility to go above and beyond what has already been done with it.

The paper accompanying this solver can be found on the [arXiv](https://arxiv.org/abs/2102.09193v1). If you use SeaPearl in your research, please cite our work.

The RL agents are defined using [ReinforcementLearning.jl](https://github.com/JuliaReinforcementLearning/ReinforcementLearning.jl), the inputs are dealt with using [GeometricFlux.jl](https://github.com/FluxML/GeometricFlux.jl). The CP part, inspired from [MiniCP](http://www.minicp.org/), is focused on readability. The code is meant to be clear and modulable so that researchers could easily get access to CP data and use it as input for their ML model.

## Installation

```julia
]add SeaPearl
```

## Use

Working examples can be found in [SeaPearlZoo](https://github.com/corail-research/SeaPearlZoo).

## Contribution

All PRs and issues are welcome.


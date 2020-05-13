# CPRL

[![Build Status](https://travis-ci.com/CPRLSolver/CPRL.jl.svg?token=txSsK23gqDP8efBDxJzv&branch=master)](https://travis-ci.com/CPRLSolver/CPRL.jl)

Hybrid solver using Constraint programming and Reinforcement learning. 
Ilan Coulon, Félix Chalumeau & Quentin Cappart. 

## Useful links 

Here are useful links 

### User interface:
Documentation of the modeling language we want to use, called JuMP http://www.juliaopt.org/JuMP.jl/v0.19.0/

### Constraint Programming:
The architecture is inspired by miniCP, which is a CP solver in Java. Here is its documentation: http://www.minicp.org/
One can also check slides used to present miniCP's structure: https://school.a4cp.org/summer2017/slidedecks/MiniCP.pdf

### Reinforcement Learning:
We are using native julia packages ReinforcementLearning.jl https://github.com/JuliaReinforcementLearning/ReinforcementLearning.jl
The types were inheriting are in ReinforcementLearningBase.jl and ReinforcementLearningCore.jl and some interesting examples can be found in ReinforcementLearningZoo.jl and ReinforcementLearningEnvironments.jl

### Machine Learning:
They are two main packages for ML at the moment. KNet.jl & Flux.jl
We are planning to use Flux.jl. Github repo : https://github.com/FluxML/Flux.jl & documentation : https://fluxml.ai/

### Working on graphs:
Even if this part is still under debate, we might be working with graphs. In this case, we will use LightGraphs.jl https://github.com/JuliaGraphs/LightGraphs.jl
And the machine learning on graphs would be eased by GeometricFlux.jl https://github.com/yuehhua/GeometricFlux.jl

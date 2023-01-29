# SeaPearl: A Julia hybrid CP solver enhanced by Reinforcement Learning techniques

SeaPearl was created as a way for researchers to have a constraint programming solver that can
integrate seamlessly with Reinforcement Learning technologies, using them as heuristics for value selection during branching.

The paper accompanying this solver can be found on the [arXiv](https://arxiv.org/abs/2102.09193v1). If you use SeaPearl in your research, please cite our work.

The Julia language was chosen for this project as we believe it is one of the few languages that can be used for Constraint Programming as well as Machine/Deep Learning.

The constraint programming part, whose architecture is heavily inspired from [Mini-CP framework](https://minicp.readthedocs.io/en/latest/intro.html), is focused on readability. The code was meant to be clear and modulable so that researchers could easily get access to CP data and use it as input for their ML model.

SeaPearl comes with a set of examples that can be found in the [SeaPearlZoo](https://github.com/corail-research/SeaPearlZoo.jl) repository.


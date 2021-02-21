# SeaPearl: A Julian hybrid CP solver enhanced by Reinforcement Learning techniques

SeaPearl was created as a way for researchers to have a constraint programming solver that can
integrate seamlessly with Reinforcement Learning technologies.

The Julia language was chosen for this project as we believe it is one of the few languages that can be used for Constraint Programming as well as Machine/Deep Learning.

The constraint programming part, whose architecture is heavily inspired from [Mini-CP framework](https://minicp.readthedocs.io/en/latest/intro.html), is focused on readability. The code was meant to be clear and modulable so that researchers could easily get access to CP data and use it as input for their ML model.



The new thing in SeaPearl is that the Reinforcement Learning part does *not* directly solve the CP problem, it is only used as a value-selection heuristic and therefore lets you use constraint propagation and different search strategies to, for example, prove optimality. The RL agent is only called when the CP solver has to branch and assign an arbitrary value to a variable.
Therefore, the RL agent can be trained to find good solutions as well as proving their optimality and is completely integrated into the CP framework.

using CPRL

model = CPRL.build_model(CPRL.FixedOutputGCN, CPRL.ArgsFixedOutputGCN(
    maxDomainSize = 11,
    numInFeatures = 47,
    firstHiddenGCN = 18,
    secondHiddenGCN = 19
))
agent = CPRL.DQNAgent(;nn_model=model)

heuristic = CPRL.LearnedHeuristic(agent)

trytrain() = CPRL.train!(; learnedHeuristic=heuristic, nb_episodes=1)
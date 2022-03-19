include("./wordle_pomdp.jl")
using POMDPPolicies: RandomPolicy

# the main script here is for running simulations with our solvers
m = wordle() 

# Basic simulation with a random policy
policy = RandomPolicy(m)
sim = RolloutSimulator(max_steps=100)
results = mean(simulate(sim, m, policy) for _ in 1:10000)

# print the mean reward
println("Mean Reward from 10,000 Runs: ", results)
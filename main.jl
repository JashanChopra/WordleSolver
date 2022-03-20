include("./wordle_pomdp.jl")
using POMDPPolicies: RandomPolicy
using POMDPSimulators: RolloutSimulator
using POMDPs: simulate
using Statistics: mean

function main()
    # the main script here is for running simulations with our solvers

    # create a Wordle game 
    words = Wordle.VALID_WORD_LIST              # get the list of all valid wordle words
    word = rand(words, 1)[1]                    # choose a random word
    game = WordleGame(word)                     # create a game

    # define the wordle POMDP 
    m = wordle() 

    # Basic simulation with a random policy
    policy = RandomPolicy(m)
    sim = RolloutSimulator(max_steps=100)
    results = mean(simulate(sim, m, policy) for _ in 1:10000)

    # print the mean reward
    println("Mean Reward from 10,000 Runs: ", results)
end

main()
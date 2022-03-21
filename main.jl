include("./wordle_pomdp.jl")
include("./helper.jl")
using POMDPPolicies: RandomPolicy
using POMDPSimulators: RolloutSimulator
using POMDPs: simulate
using Statistics: mean

function main()
    # define the wordle POMDP 
    m = wordle() 

    # number of games to run 
    n = 10

    # a policy that cheats to always get the correct answer
    println("Testing a cheating policy")
    policy = winning_policy
    reward, correct = evaluate_policy(m, policy, n)
    println("The average reward over ", n, " games for the cheating policy was: ", reward)
    println("Our of ", n, " games, ", correct, " were correctly guessed")

    println("-------------------")

    # a policy that random guesses words
    println("Testing a random policy")
    policy = random_policy
    reward, correct = evaluate_policy(m, policy, n)
    println("The average reward over ", n, " games for the random policy was: ", reward)
    println("Our of ", n, " games, ", correct, " were correctly guessed")

    # additional simulations here
end

main()
using POMDPPolicies: RandomPolicy
using POMDPSimulators: RolloutSimulator
using POMDPs: simulate
using Statistics: mean

# include functions that contain your policies for testing 
include("./wordle_pomdp.jl")
include("./helper.jl")

function main()
    # define the wordle POMDP 
    m = wordle() 

    # a policy that cheats to always get the correct answer
    # note: the score returned from this is the maximum we could possibly see
    n = 5 # number of games to run 
    println("Testing a cheating policy")
    policy = winning_policy
    reward, correct = evaluate_policy(m, policy, n)
    println("The average reward over ", n, " games for the cheating policy was: ", reward)
    println("Our of ", n, " games, ", correct, " were correctly guessed")

    println("-------------------------------------------------------------------")

    # todo: update the random policy so that it follows more in line with the POMDP format 
    # i.e: instead of our random guess coming from random_policy() have it return 
    # a random action from the wordle() POMDP

    # a policy that random guesses words
    # note: if a policy does worse than this, we are not doing well 
    n = 25000 
    println("Testing a random policy")
    policy = random_policy
    reward, correct = evaluate_policy(m, policy, n)
    println("The average reward over ", n, " games for the random policy was: ", reward)
    println("Out of ", n, " games, ", correct, " were correctly guessed")

    # additional simulations here
end

main()
using POMDPPolicies: RandomPolicy
using POMDPSimulators
using POMDPs
using Statistics: mean
using QMDP: QMDPSolver
using BeliefUpdaters: DiscreteUpdater
using POMDPModelTools

# include functions that contain your policies for testing 
include("./wordle_pomdp.jl")
include("./helper.jl")

function main()
    # define the wordle POMDP 
    m = wordle() 

    # # a policy that cheats to always get the correct answer
    # # note: the best possible score is 1.0 (the first guess wins) 
    # n = 10 # number of games to run 
    # println("Testing a cheating policy")
    # policy = winning_policy
    # @time reward, correct = evaluate_policy(m, policy, n)
    # println("The average reward over ", n, " games for the cheating policy was: ", reward)
    # println("Our of ", n, " games, ", correct, " were correctly guessed")

    # println("-------------------------------------------------------------------")

    # # a policy that random guesses words
    # # note: the worse possible score is 7.0
    #     # if we win in 6 turns, the score is 6.0 
    #     # if the game isn't won (i.e: the 6th guess is wrong), the score is 7.0 
    # n = 100
    # println("Testing a random policy")
    # policy = random_policy
    # @time reward, correct = evaluate_policy(m, policy, n)
    # println("The average reward over ", n, " games for the random policy was: ", reward)
    # println("Out of ", n, " games, ", correct, " were correctly guessed")

    # Evaluate with the QMDP Solver
    solver = QMDPSolver()
    policy = solve(solver, m)
    rsum = 0.0
    for (s,b,a,o,r) in stepthrough(m, policy, "s,b,a,o,r", max_steps=10)
        println("s: $s, b: $([s=>pdf(b,s) for s in states(m)]), a: $a, o: $o")
        println(r)
        rsum += r
    end
    println("Undiscounted reward was $rsum.")
end

main()
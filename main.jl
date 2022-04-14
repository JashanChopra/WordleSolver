using POMDPs
using POMDPPolicies
using POMDPSimulators
using POMDPModelTools
using POMDPTesting
using Statistics: mean
using QMDP
using SARSOP
using BeliefUpdaters
using LinearAlgebra: dot

# include functions that contain policies for evaluation 
include("./wordle_pomdp.jl")
include("./helper.jl")
include("./qmdp.jl")

function main()
    # for testing with a much smaller list 
    # note: restart VSCode if you plan on using the full list after running this 
    @eval Wordle VALID_WORD_LIST = ["hello", "world", "guess", "pizza", "stand", "table", "watch"]

    println("Starting Wordle Solver!")

    # define the wordle POMDP 
    m = create_wordle() 
    println("Created Wordle POMDP")

    # this takes a long time to run with the full state space, good for checking with smaller word list though 
    # @assert has_consistent_distributions(m)

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

    # println("-------------------------------------------------------------------")

    # a heuristic policy based on eliminating words 
    # n = 1000
    # println("Testing a heuristic policy")
    # policy = heuristic_policy
    # @time reward, correct = evaluate_policy(m, policy, n)
    # println("The average reward over ", n, " games for the random policy was: ", reward)
    # println("Out of ", n, " games, ", correct, " were correctly guessed")

    # println("-------------------------------------------------------------------")

    # Use HW6 updater
    up = HW6Updater(m)
    println("Testing a QMDP generated policy")
    policy = qmdp_solve(m)
    @show policy

    print("\nRunning regular simulation")
    @show mean(simulate(RolloutSimulator(max_steps = 10), m, policy, up) for _ in 1:1000)
    # rsum = 0.0
    # for (s,b,a,o,r) in stepthrough(m, policy, "s,b,a,o,r", max_steps=10)
    #     println("s: $s, b: $([s=>pdf(b,s) for s in states(m)]), a: $a, o: $o")
    #     println(r)
    #     rsum += r
    # end
    # println("Undiscounted reward was $rsum.")

    # History recorded to see how it's working
    # Running history recorder
    print("\nRunning history recorder")
    hr = HistoryRecorder(max_steps = 10)
    h = simulate(hr,m,policy,up)
    println("Discounted reward = ", discounted_reward(h))
    println("State history ", state_hist(h))
    println("\nEach step a,o history: \n",collect(eachstep(h, "a,o")))

    # println("-------------------------------------------------------------------")
end

main()
module WordleSolver

# POMDP Modules
using POMDPs
using POMDPPolicies
using POMDPSimulators
using POMDPModelTools
using POMDPTesting
using QMDP
using SARSOP
using BeliefUpdaters

# Misc Modules
using Statistics: mean
using LinearAlgebra: dot
using StatsBase: sample

# additional functions
include("./wordle_pomdp.jl")
include("./helper.jl")
include("./qmdp.jl")

function main(debug, small, set_size)
    # :param: logging: whether to print extra debugging statements 
    # :param: small: use a smaller word list for testing 

    # set the logging bool 
    global logging = debug

    # set the word list 
    full_set = deepcopy(Wordle.VALID_WORD_LIST)
    if small 
        small_set = sample(full_set, set_size; replace=false)
        global words = small_set
        logging && println(words)
    else
        global words = full_set
    end
    
    # define the wordle POMDP 
    println("Starting Wordle Solver!")
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
    println("Creating a policy using QMDP")
    policy = qmdp_solve(m)

    println("QMDP Rollout Simulator")
    @show mean(simulate(RolloutSimulator(max_steps = 10), m, policy, up) for _ in 1:1000)

    # History recorded to see how it's working
    # Running history recorder
    println("Running history recorder with QMDP Policy")
    hr = HistoryRecorder(max_steps = 10, show_progress=true)
    h = simulate(hr,m,policy,up)
    println("Discounted reward = ", discounted_reward(h)) 
    logging && println("State history ", state_hist(h))
    logging && println("Each step a,o history: \n",collect(eachstep(h, "a,o")))

    if logging 
        for (s, a, r, sp, o, bp) in eachstep(h, "(s, a, r, sp, o, bp)")    
            println("For state $s, we guessed action $a")
            # println("We saw observation $o, and updated the belief to be $(bp.b)")
            println("We entered state $sp, and received reward $r")
        end
    end

    println("-------------------------------------------------------------------")
end # end main()
end # end module

debug = true    # log extra stuff throughout various files
small = true    # test with a smaller word list 
set_size = 100  # smaller word list size
WordleSolver.main(debug, small, set_size)
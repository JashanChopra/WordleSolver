using POMDPs
using POMDPPolicies
using POMDPSimulators
using POMDPModelTools
using Statistics: mean
using QMDP
using BeliefUpdaters


# include functions that contain policies for evaluation 
include("./wordle_pomdp.jl")
include("./helper.jl")

# using POMDPs
# using DMUStudent.HW6
# using POMDPModelTools: transition_matrices, reward_vectors, SparseCat, Deterministic, weighted_iterator, obs_weight
# using QuickPOMDPs: QuickPOMDP
# using POMDPModels: TigerPOMDP
# using POMDPSimulators: RolloutSimulator
# using BeliefUpdaters: DiscreteBelief, DiscreteUpdater
# using SARSOP: SARSOPSolver
# using QMDP: QMDPSolver
# using POMDPTesting: has_consistent_distributions
# using POMDPPolicies: FunctionPolicy
# using LinearAlgebra: dot


# # Updater structure and function 
# struct HW6Updater{M<:POMDP} <: Updater
#     m::M
# end

# function Z(m::POMDP, a, sp, o)
#     # return a probability from a POMDP's observation table for a given action, future state, and observation
#     return pdf(observation(m, a, sp), o)
# end

# function T(m::POMDP, s, a, sp)
#     # return a probability from a POMDP's transition table for a given state, action, and future state
#     return pdf(transition(m, s, a), sp)
# end

# function POMDPs.update(updater::HW6Updater, b::DiscreteBelief, a, o)
    
#     # perform a belief update with a discrete Bayesian filter
#     pomdp = updater.m
#     S = states(pomdp)

#     # the new belief
#     belief = zeros(length(S))

#     # update the belief vector for each state in the POMDP 
#     for s in S
#         prob_observation = Z(pomdp, a, s, o)
#         prob_transition_sum = sum((T(pomdp, s, a, sp) * b.b[stateindex(pomdp, sp)]) for sp in S)
#         belief[stateindex(pomdp, s)] = prob_observation * prob_transition_sum
#     end

#     # normalize the belief
#     belief ./= sum(belief) 

#     return DiscreteBelief(updater.m, belief, check=true)
# end

# function POMDPs.initialize_belief(updater::HW6Updater, distribution::Any)
#     # initialize the belief as a vector of zeros, with length equal to the number of states in the POMDP
#     belief = zeros(length(states(updater.m)))

#     # for each state, initialize a belief based on the given distribution 
#     for s in states(updater.m)
#         belief[stateindex(updater.m, s)] = pdf(distribution, s)
#     end
#     return DiscreteBelief(updater.m, belief)
# end

function main()
    # define the wordle POMDP 
    m = wordle() 
    @assert has_consistent_distributions(m)

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
    # up = HW6Updater(m)
    up = DiscreteUpdater(m)
    policy = solve(solver, m)
    @show mean(simulate(RolloutSimulator(), m, policy, up) for _ in 1:1000)
    rsum = 0.0
    for (s,b,a,o,r) in stepthrough(m, policy, "s,b,a,o,r", max_steps=10)
        println("s: $s, b: $([s=>pdf(b,s) for s in states(m)]), a: $a, o: $o")
        println(r)
        rsum += r
    end
    println("Undiscounted reward was $rsum.")
end

main()
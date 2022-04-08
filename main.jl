using POMDPs
using POMDPPolicies
using POMDPSimulators
using POMDPModelTools
using POMDPTesting
using Statistics: mean
using QMDP
using BeliefUpdaters
using LinearAlgebra: dot

# include functions that contain policies for evaluation 
include("./wordle_pomdp.jl")
include("./helper.jl")
include("./value_iteration.jl")

# Updater structure and function 
struct HW6Updater{M<:POMDP} <: Updater
    m::M
end

function Z(m::POMDP, a, sp, o)
    # return a probability from a POMDP's observation table for a given action, future state, and observation
    return pdf(observation(m, a, sp), o)
end

function T(m::POMDP, s, a, sp)
    # return a probability from a POMDP's transition table for a given state, action, and future state
    return pdf(transition(m, s, a), sp)
end

function POMDPs.update(updater::HW6Updater, b::DiscreteBelief, a, o)
    # perform a belief update with a discrete Bayesian filter
    pomdp = updater.m
    S = ordered_states(pomdp)

    # the new belief
    b_prime = zeros(length(S))

    # update the belief vector for each state in the POMDP 
    for (sp_idx, sp) in enumerate(S)
        po = Z(pomdp, a, sp, o)
        pt = 0.0 
        for (s_idx, s) in enumerate(S)
            pt += T(pomdp, s, a, sp) * b.b[s_idx]
        end
        b_prime[sp_idx] = po * pt
    end

    # normalize the belief
    b_prime ./= sum(b_prime) 

    return DiscreteBelief(updater.m, b_prime, check=true)
end

function POMDPs.initialize_belief(updater::HW6Updater, distribution::Any)
    # initialize the belief as a vector of zeros, with length equal to the number of states in the POMDP
    states = ordered_states(updater.m)
    belief = zeros(length(states))

    # for each state, initialize a belief based on the given distribution 
    for s in ordered_states(updater.m)
        belief[stateindex(updater.m, s)] = pdf(distribution, s)
    end
    return DiscreteBelief(updater.m, belief)
end

# Policy & action function 
struct HW6AlphaVectorPolicy{A} <: Policy
    alphas::Vector{Vector{Float64}}
    alpha_actions::Vector{A}
end

function POMDPs.action(p::HW6AlphaVectorPolicy, b::DiscreteBelief)
    # given a belief b, find the alpha vector that gives the higehst value at that belief point
    idx = argmax([dot(a, b.b) for a in p.alphas])
    return p.alpha_actions[idx]
end

# QMDP Solver function 
function qmdp_solve(m, discount=discount(m))

    # turn the POMDP into an MDP and perform value iteration 
    mdp = UnderlyingMDP(m)
    
    # load in the transition matrices and rewards
    T = POMDPModelTools.transition_matrices(mdp)
    R = POMDPModelTools.reward_vectors(mdp)
    tol = 1e-35         # convergence tolerance
    loops = 1e7         # maximum number of 
    
    # perform value iteration 
    _, _, Qmatrix = value_iteration_vectorized(m, T, R, tol, discount, loops)

    # the psuedoalpha vectors are the Qmatrix entries
    acts = ordered_actions(m)
    alphas = Vector{Float64}[]
    for (i, _) in enumerate(acts)
        push!(alphas, Qmatrix[i, :])
    end
    println(alphas) 
    return HW6AlphaVectorPolicy(alphas, acts)
end

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

    # Evaluate with the HW6 QMDP Solver for checking     
    # solver = qmdp_solve(m)
    # up = HW6Updater(m)
    solver = QMDPSolver()
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
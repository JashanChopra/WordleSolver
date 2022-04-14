include("./value_iteration.jl")
using BeliefUpdaters

# QMDP solver from HW6 
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

    # Number of words in observation
    n = length(o[1])

    # If we run out of words just set belief as a uniform distribution since state is gonna reset anyways
    if o[2] + 1 >= 7
        b_prime = b_prime*1/length(S)
    end

    # Nasty for loops but probably a better way of doing this
    for (_,o_word) in enumerate(o[1])
        for (s_idx, s) in enumerate(S)
            if s[1] == o_word && s[2] == o[2] + 1
                b_prime[s_idx] = 1/n
            end
        end
    end

    # Check belief adds up to 1
    b_prime_sum = sum(b_prime)

    return DiscreteBelief(updater.m, b_prime, check=false)
end

function POMDPs.initialize_belief(updater::HW6Updater, distribution::Any)
    # initialize the belief as a vector of zeros, with length equal to the number of states in the POMDP
    states = ordered_states(updater.m)
    belief = zeros(length(states))

    # for each state, initialize a belief based on the given distribution 
    # Only initialize states with index of 0
    for s in ordered_states(updater.m)
        if s[2] == 0
            belief[stateindex(updater.m, s)] = pdf(distribution, s)
        end
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
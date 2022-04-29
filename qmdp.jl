include("./value_iteration.jl")

# QMDP solver from HW6 
# Updater structure and function 
struct HW6Updater{M<:POMDP} <: Updater
    m::M
end

# function Z(m::POMDP, a, sp, o)
#     # return a probability from a POMDP's observation table for a given action, future state, and observation
#     return pdf(observation(m, a, sp), o)
# end

# function T(m::POMDP, s, a, sp)
#     # return a probability from a POMDP's transition table for a given state, action, and future state
#     return pdf(transition(m, s, a), sp)
# end

function POMDPs.update(updater::HW6Updater, b::DiscreteBelief, a, o)
    # perform a belief update with a discrete Bayesian filter
    pomdp = updater.m
    S = ordered_states(pomdp)

    # the new belief
    b_prime = zeros(length(S))

    # Number of words in observation
    n = length(o[1])
    # print("\n\nAction: ",a)
    # print("\nObservation: ",o)

    # If we run out of words just set belief as a uniform distribution since state is gonna reset anyways
    if o[2] + 1 >= 7
        b_prime = b_prime*1/length(S)
    end

    # Nasty for loops but probably a better way of doing this
    # print("\nNew belief for relevant states: b(s) = ",1/n)
    # print("\nIterating through observations to update belief for relevant states: ")
    for (_,o_word) in enumerate(o[1])
        # print("\n    Observation: ",o_word)
        # print("\n    Relevant states: ")
        for (s_idx, s) in enumerate(S)
            if s[1] == o_word && s[2] == o[2] + 1
                # print("\n        ",s)
                b_prime[s_idx] = 1/n
            end
        end
    end

    # Check belief adds up to 1
    # print("\nFinal sum of beliefs = ",sum(b_prime))
    # println("New belief vector ", b_prime)

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
            # belief[stateindex(updater.m, s)] = pdf(distribution, s)
            # print("stateindex(updater.m, s)")
            belief[stateindex(updater.m, s)] = 1/length(words)
        end
    end
    # println("Initial belief = ",belief)
    # print("\nFinal sum of beliefs = ",sum(belief))
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

function generate_transition_mat(mdp::Union{MDP, POMDP})

    A = ordered_actions(mdp)
    S = ordered_states(mdp)
    ns = length(S)
    na = length(A)

    logging && println("Preallocating")
    T = Dict(name => zeros(Bool,ns,ns) for name in A)
    for (a_idx,a) in enumerate(A)
        logging && println("Action ", a)
        for (s_idx,s) in enumerate(S)
            if a == s[1] || s[2] == 7
                # If action same as true word OR state corresponds to a pre-terminal state (tunr number = 7)
                # everything stays at 0 except state with same target word but turn number -1 (terminal state)
                println(a)
                if mod(s_idx,na) == 0
                    T[a][s_idx,na] = true
                else
                    T[a][s_idx,mod(s_idx,na)] = true
                end
            elseif s[2] != -1
                # If action is anything else (but state isn't terminal), set state with same true word but next turn number to 1
                T[a][s_idx,s_idx + na] = true
            end
            # Otherwise everything stays at zero
        end
    end
    return(T)
end

# QMDP Solver function 
function qmdp_solve(m, discount=discount(m))

    # turn the POMDP into an MDP and perform value iteration 
    mdp = UnderlyingMDP(m)
    
    # load in the transition matrices and rewards
    # logging && println("Generating transition matrix")
    # T = generate_transition_mat(m)
    T = 10;
    logging && println("Generating reward matrix")
    # R = POMDPModelTools.reward_vectors(mdp)
    R = 10;
    tol = 1e-3         # convergence tolerance
    loops = 1e6        # maximum number of 
    # logging && println("Size of transition matrix", size(T[actions(m)[1]]))
    
    # perform value iteration 
    _, _, Qmatrix = value_iteration_vectorized(m, T, R, tol, discount, loops)
    logging && println("Value iteration done.")

    # the psuedoalpha vectors are the Qmatrix entries
    acts = ordered_actions(m)
    alphas = Vector{Float64}[]
    for (i, _) in enumerate(acts)
        push!(alphas, Qmatrix[i, :])
    end
    # println(alphas) 
    return HW6AlphaVectorPolicy(alphas, acts)
end
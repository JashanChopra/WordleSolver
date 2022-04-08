# Common functions for question 3 and question 4 of HW2
using DMUStudent.HW2
using POMDPs: states, actions, stateindex
using POMDPModelTools: render

# lookahead implements the loopup eqn (algo 7.2 in book)
function lookahead(V, T, R, s, n, a, gamma)
    # get the current reward 
    curr_reward = R[a][s]

    # get the sum of future rewards 
    tv = 0.0
    for s_prime in 1:n        
        tv += convert(Float64, T[a][s, s_prime] * V[s_prime])
    end

    # return the current reward + the future rewards
    return curr_reward + gamma * tv
end

# the Bellman backup / Bellman update (algo 7.7 in book)
function backup(V, T, R, s, n, gamma)
    # appending to the vector and taking the max is faster than comparing each value 
    A = collect(keys(R))        
    lookup_maxes = Float64[]

    # loop over each action 
    for a in A
        append!(lookup_maxes, lookahead(V, T, R, s, n, a, gamma))
    end
    return maximum(lookup_maxes)

    # # This is slower
    # lookup_max = 0.0
    # for a in A
    #     lookup_val = lookahead(V, T, R, s, n, a, gamma)
    #     if lookup_val > lookup_max
    #         lookup_max = lookup_val
    #     end
    # end
    # return lookup_max
end

# value iteration (algo 7.8 in the book)
function value_iteration(m, T, R, tol, gamma, max_loops, print=false)
    # param: m: the MDP [Type: ACASState]
    # param: T: the transition matrix (see transition_matrices)
    # param: R: the reward vector (see reward_vectors())
    # param: tol: the tolerance
    # param: gamma: the discount factor
    # param: print: whether to print the index at each iteration

    # setup 
    state_vec = states(m)   # type Vector{ACASState}
    n = length(state_vec)   # int64
    total_loops = 0         # int64

    # initialize the two value vectors with random numbers
    V = rand(n)
    V_prime = rand(n)
    
    while true 
        # update value vector with the next state
        V = copy(V_prime)

        # apply bellman's equation for each state
        for s in 1:n
            # update the value equation 
            V_prime[s] = backup(V, T, R, s, n, gamma)
        end

        # increment the loop counter
        total_loops += 1

        # printing loop counter for debugging
        if print == true
            println("loop #", total_loops)
        end

        # check for convergence below the input tolerance
        if maximum(abs.(V - V_prime)) < tol 
            return V_prime, total_loops
        end

        # check for the total number of loops reached 
        if total_loops > 1000
            return V_prime, total_loops
        end
    end
end

# vectorized version of the value iteration 
function value_iteration_vectorized(m, T, R, tol, gamma, max_loops, print=false)
    # param: m: the MDP [Type: ACASState]
    # param: T: the transition matrix (see transition_matrices)
    # param: R: the reward vector (see reward_vectors())
    # param: tol: the tolerance
    # param: gamma: the discount factor
    # param: print: whether to print the index at each iteration

    # setup 
    state_vec = states(m)   # type Vector{ACASState}
    n = length(state_vec)   # int64
    total_loops = 0         # int64

    # initialize the two value vectors with random numbers
    V = rand(n)
    V_prime = rand(n)
    
    while maximum(abs.(V_prime - V)) > tol
        # update value vector with the next state
        V = V_prime

        # apply bellman's equation
        A = collect(keys(R))
        max_matrix = Array{Float64, 2}(undef, length(A), n)   # each row is for an action 
        for (idx, a) in enumerate(A) 
            # the current reward vector 
            curr_reward = R[a]    

            # future reward matrix
            tv_matrix = T[a]*V

            # update max_matrix
            max_matrix[idx, :] = curr_reward + gamma .* tv_matrix
        end
        # get the maximum along the rows, that's the new value vector
        V_prime = vec(maximum(max_matrix, dims=1))
    
        # increment the loop counter
        total_loops += 1

        # printing loop counter for debugging
        if print == true
            println("loop #", total_loops)
        end

        # check for the total number of loops reached 
        if total_loops > max_loops
            break
        end
    end
    return V_prime, total_loops
end

# stuff to improve speed
# - use a sparse matrix for the transition matrix
    # the sparse matrix loads in 0.065 seconds as compared to 1 second at n = 2
    # at n = 7, the non-sparse transition matrix will not even load
    # the sparse matrix loads in 6.556 seconds, I need to only be loading that in once
# - implement type stable arrays
    # Helped slightly
# - vectorize the Functions
    # Helped a lot
# - find a new algorithim 
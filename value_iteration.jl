using POMDPs

# vectorized value iteration from HW2 
# modified to return the q matrix as well 
function value_iteration_vectorized(m, T, R, tol, gamma, max_loops)
    logging && println("Runnning value iteration")
    # setup 
    ns = length(states(m))
    na = length(actions(m))
    V = rand(ns)
    V_prime = rand(ns)
    qmat = zeros(ns, na)
    total_loops = 0

    # run until we reach the tolerance
    while maximum(abs.(V_prime - V)) > tol
        # update value vector with the next state
        V = V_prime

        A = ordered_actions(m)
        max_matrix = Array{Float64, 2}(undef, length(A), ns)
        logging && println("Enumerating action space ")
        for (a_idx, a) in enumerate(A)
            # value iteration update formula
            curr_reward = R[a]    
            tv_matrix = T[a]*V
            max_matrix[a_idx, :] = curr_reward + gamma .* tv_matrix
        end 
        # logging && println("Computing v_prime")
        qmat = max_matrix
        V_prime = vec(maximum(max_matrix, dims=1))

        total_loops += 1
        logging && println("Number of loops ", total_loops)

        # check for the total number of loops reached 
        if total_loops > max_loops
            break
        end
    end
    return V_prime, total_loops, qmat
end
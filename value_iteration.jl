using POMDPs

# vectorized value iteration from HW2 
# modified to return the q matrix as well 
function value_iteration_vectorized(m, T, R, tol, gamma, max_loops)
    logging && println("Runnning value iteration...")
    # setup 
    S = ordered_states(m)
    A = ordered_actions(m)
    ns = length(S)
    na = length(A)
    V = rand(ns)
    V_prime = rand(ns)
    qmat = zeros(ns, na)
    total_loops = 0

    # run until we reach the tolerance
    while maximum(abs.(V_prime - V)) > tol
        # update value vector with the next state
        V = V_prime

        # max_matrix = Array{Float64, 2}(undef, na, ns)
        # logging && println("Preallocating max_mat")
        max_matrix = Array{Float64}(zeros(na,ns))

        # logging && println("Enumerating action space ")
        # for (a_idx, a) in enumerate(A)
        #     # value iteration update formula
        #     curr_reward = R[a]    
        #     tv_matrix = T[a]*V
        #     max_matrix[a_idx, :] = curr_reward + gamma .* tv_matrix
        # end  
        t = time() 
        for (a_idx, a) in enumerate(A)
            t_2 = time()
            for (s_idx,s) in enumerate(S)
                curr_reward = reward(m, s, a)
                if (a == s[1] || s[2] == 7) && s[2] != -1
                    if mod(s_idx,na) == 0
                        max_matrix[a_idx, s_idx] = curr_reward + V[na]
                    else
                        max_matrix[a_idx, s_idx] = curr_reward + V[mod(s_idx,na)]
                    end
                elseif s[2] != -1
                    max_matrix[a_idx, s_idx] = curr_reward + V[s_idx + na]
                end
                # @show s 
                # @show a
                # @show curr_reward
                # @show max_matrix[a_idx, s_idx]
            end 
            if logging && (mod(a_idx,100) == 0)
                println("Action index ", a_idx,"/",na, " Time = ",time() - t_2, 's')
            end
            
        end 
        # logging && println("Computing v_prime")
        qmat = max_matrix
        V_prime = vec(maximum(max_matrix, dims=1))

        total_loops += 1
        logging && println("Iteration ", total_loops, " Max error = ", maximum(abs.(V_prime - V)), " Time = ", time() - t, 's')
 
        # check for the total number of loops reached 
        if total_loops > max_loops
            break
        end
    end
    return V_prime, total_loops, qmat
end
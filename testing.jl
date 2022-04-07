using POMDPs 
using POMDPModelTools
using POMDPModels
using POMDPSimulators
using POMDPPolicies
using Statistics: mean
using QuickPOMDPs
using BeliefUpdaters
using QMDP 
using SARSOP 
using POMDPTesting 
using BasicPOMCP 
using DiscreteValueIteration

function cancer_transition(s, a)
    # transition function for the cancer POMDP provided
    # takes in s and a and returns the distribution of s'

    # the transition table given provides the probability of moving to a given s'
    # otherwise we just stay in state s
    if s == :healthy
        return SparseCat([:healthy, :insitu], [0.98, 0.02])
    elseif s == :insitu
        if a == :treat
            return SparseCat([:healthy, :insitu], [0.6, 0.4])
        else
            return SparseCat([:insitu, :invasive], [0.9, 0.1])
        end
    elseif s == :invasive
        if a == :treat
            return SparseCat([:healthy, :death, :invasive], [0.2, 0.2, 0.6])
        else
            return SparseCat([:invasive, :death], [0.4, 0.6])
        end
    else
        return Deterministic(:death)
    end
end

function cancer_observation(a, sp)
    # observation function for the cancer POMDP provided
    # observation should be a function that takes in s, a, and sp, and returns the distribution of o
    if a == :test 
        if sp == :healthy
            return SparseCat([:pos, :neg], [0.05, 0.95])   
        elseif sp == :insitu
            return SparseCat([:pos, :neg], [0.80, 0.20])
        else
            return Deterministic(:pos)
        end
    elseif a == :treat
        if sp == :insitu
            return Deterministic(:pos)
        elseif sp == :invasive 
            return Deterministic(:pos)
        else 
            return Deterministic(:neg)
        end
    else 
        return Deterministic(:neg)
    end
end

function cancer_reward(s, a)
    # reward function for the cancer POMDP provided
    if s == :death 
        return 0.0
    else # s = :healthy, :insitu, :invasive
        if a == :wait 
            return 1.0 
        elseif a == :test 
            return 0.8 
        elseif a == :treat 
            return 0.1 
        else 
            error(a, "Action undefined")
        end
    end
end

function cancer()
    # setup the cancer monitoring and treatment plan using QuickPOMDP
    m = QuickPOMDP(
        states = [:healthy, :insitu, :invasive, :death],
        actions = [:wait, :test, :treat],
        observations = [:pos, :neg],
        transition = cancer_transition,
        observation = cancer_observation,
        reward = cancer_reward,
        initialstate = Deterministic(:healthy),
        discount = 0.99,
        isterminal = s->s==:death,
    )
    return m
end

function tests()
    # Define various POMDPs
    cancer = cancer() 
    @assert has_consistent_distributions(cancer)
    tiger = TigerPOMDP()
    @assert has_consistent_distributions(tiger)
    baby = CryingBaby() 
    @assert has_consistent_distributions(baby)

    # QMDP on Cancer Problem
    qmdp_p = solve(QMDPSolver(), cancer)
    up = HW6Updater(cancer)
    println("QMDP Solver - Cancer POMDP")
    rewards = [simulate(RolloutSimulator(max_steps=500), cancer, qmdo_p, up) for _ in 1:1000]
    mea = mean(rewards) 
    println("Mean Reward: ", mea)
    println("SEM: ", mea / sqrt(length(rewards)))
    println("------------------------------------------------------")

    # SARSOP on Cancer Problem
    sarsop_p = solve(SARSOPSolver(), cancer)
    up = HW6Updater(cancer)
    println("SARSOP Solver - Cancer POMDP")
    rewards = [simulate(RolloutSimulator(max_steps=500), cancer, sarsop_p, up) for _ in 1:1000]
    mea = mean(rewards) 
    println("Mean Reward: ", mea)
    println("SEM: ", mea / sqrt(length(rewards)))
    println("------------------------------------------------------")

    # POMCP on Cancer Problem  
    svis = SparseValueIterationSolver(max_iterations=1000, belres=1e-7, verbose=true)
    mdp = UnderlyingMDP(cancer)
    value_policy = solve(svis, mdp) 
    solver = POMCPSolver(tree_queries = 1000, max_time = 0.25, c=200.0, max_depth=20, default_action = :wait, estimate_value = FORollout(value_policy))
    policy = solve(solver, cancer)
    up = DiscreteUpdater(cancer)
    println("POMCP Solver - Cancer POMDP")
    rewards = [simulate(RolloutSimulator(max_steps=500), cancer, policy, up) for _ in 1:1000]
    mea = mean(rewards) 
    println("Mean Reward: ", mea)
    println("SEM: ", mea / sqrt(length(rewards)))
    println("------------------------------------------------------")
end

tests()

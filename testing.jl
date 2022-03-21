using POMDPPolicies: FunctionPolicy, RandomPolicy
using POMDPSimulators
using Statistics: mean
using POMDPs, QuickPOMDPs, POMDPModelTools, POMDPSimulators, QMDP
using BeliefUpdaters


# this is the POMDP we defined in Q1 of HW5. 
# ideally we would like to define our Wordle POMDP similar to this
# we can see in the "question1" function, that we can evaluate with a policy that always waits 
# we can also solve with the QMDP solver, a built in solver for POMDPs
# but not we cannot get a policy from QMDP and then run that through a RolloutSimulator 
    # this is where I get confused 
    # it seems like there's different ways to solve POMDPs and MDPs 
    # or at least evaluate them? 


function cancer_transition(s, a)
    # transition function for the cancer POMDP provided
    # takes in s and a and returns the distribution of s'

    # the transition table given provides the probability of moving to a given s'
    # otherwise we just stay in state s
    if s == :healthy
        return SparseCat([s, :insitu], [0.98, 0.02])
    elseif s == :insitu
        if a == :treat 
            return SparseCat([s, :healthy], [0.4, 0.6]) 
        else
            return SparseCat([s, :invasive], [0.9, 0.1]) 
        end
    elseif s == :invasive
        if a == :treat 
            return SparseCat([s, :healthy, :death], [0.6, 0.2, 0.2]) 
        else
            return SparseCat([s, :death], [0.4, 0.6])
        end
    else 
        return SparseCat([s], [1.0])
    end
end

function cancer_observation(s, a, sp)
    # observation function for the cancer POMDP provided
    # observation should be a function that takes in s, a, and sp, and returns the distribution of o
    if a == :test 
        if sp == :healthy
            return SparseCat(observations, [0.05, 0.95])   
        elseif sp == :insitu
            return SparseCat(observations, [0.80, 0.20])
        elseif sp == :invasive
            return SparseCat(observations, [1.0, 0.0])
        else
            return SparseCat(observations, [0.0, 1.0])
        end
    elseif a == :treat
        if sp == :insitu
            SparseCat(observations, [1.0, 0.0])
        elseif sp == :invasive 
            SparseCat(observations, [1.0, 0.0])
        else 
            return SparseCat(observations, [0.0, 1.0])
        end
    else 
        return SparseCat([:negative], [1.0])
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

function wait()
    # policy that always returns the :wait action 
    return :wait
end

function question1()
    # setup the cancer monitoring and treatment plan using QuickPOMDP
    m = QuickPOMDP(
        states = [:healthy, :insitu, :invasive, :death],
        actions = [:wait, :test, :treat],
        observations = [:pos, :neg],
        transition = cancer_transition,
        observation = cancer_observation,
        reward = cancer_reward,
        initialstate = SparseCat([:healthy], [1.0]),
        discount = 0.99
    )
        
    # Evaluate with policy that always waits
    policy = FunctionPolicy(o->wait())
    sim = RolloutSimulator(max_steps=100)
    results = mean(simulate(sim, m, policy) for _ in 1:10000)
    # print the mean reward
    println("Mean Reward from 10,000 Runs: ", results)

    # Evaluate with the QMDP Solver
    solver = QMDPSolver()
    policy = solve(solver, m)
    rsum = 0.0
    for (s,b,a,o,r) in stepthrough(m, policy, "s,b,a,o,r", max_steps=10)
        println("s: $s, b: $([s=>pdf(b,s) for s in states(m)]), a: $a, o: $o")
        println(r)
        rsum += r
    end
    println("Undiscounted reward was $rsum.")

    # it seems with a "belief" we can then use the policy to choose an action 
    # this may be how we do it with the POMDP method? 
    # this is basically saying if our belief is that there is an equal probability between each state
    b = uniform_belief(m) # initialize to a uniform belief
    a = action(policy, b)
    println("Given belief ", b, " we choose action ", a)

    # note: this will not work with the policy defined from QMDPSolver... why? 
    # sim = RolloutSimulator(max_steps=100)
    # results = mean(simulate(sim, m, policy) for _ in 1:10000)
    # # print the mean reward
    # println("Mean Reward from 10,000 Runs: ", results)
end

# wrap the question inside a timing function 
function timed()
    @time question1()
end

timed()
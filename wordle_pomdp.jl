# This script defines Wordle as a POMDP for usage with the typical Julia libraries

using QuickPOMDPs: QuickPOMDP
using POMDPModelTools: SparseCat
using Wordle

function wordle_states()
    # :output: states: Array[Array[Symbol]]
    # the state comes from the Wordle.jl "WordleResponse" class 

    # the wordle symbols correspond to the following:
        # Wordle.CORRECT : "green" guess
        # Wordle.PRESENT : "yellow" guess
        # Wordle.INCORRECT : "black" guess
    # each state is an Array[Symbol] containing a symbol cooresponding to the guess type
    # :c = Wordle.CORRECT, :p = Wordle.PRESENT, :i = Wordle.INCORRECT
    # example: [:c, :p, :i, :c, :i]

    # define the possible symbols 
    correct = :c
    present = :p
    incorrect = :i

    # construct all possible states 
    # todo: how to do this efficiently, I'm so bad at Combinatorics 
    states = Array[]

    return states
end

function wordle_actions()
    # a valid action is guessing a valid word 
    # get the list of all valid wordle words
    words = Wordle.VALID_WORD_LIST

    # convert each string in the list into symbols 
    actions = Symbol[]
    for word in words 
        push!(actions, Symbol(word))
    end
    return actions
end

function wordle_observations()
    return [:test]
end

function wordle_transition(s, a)
    # the transitions are difficult for this...
    # technically there isn't really a probability that a future word will be guessed based on the current word?
    # we could perhaps just include a default error rate 
        # something like we guess a totally different word 5% of the time? 
        # it doesn't really make sense though  
        # do we have to have a transition probability? 

    # for now, just 100% chance of returning the same state
    return SparseCat([s], [1.0])
end

function wordle_observation_probs(s, a, sp)
    # same issue here as the transitions.. 

    SparseCat([:test], [1.0])
end

function wordle_reward(s, a)
    # :param: s: the current state
    # :param: a: the action, a Symbol object cooresponding to a 5 letter word from wordle_actions()

    # todo: we may have to adjust these rewards... they are not set in stone 

    # a green guess [:c] (letter is in the right spot) is worth 10 points 
    # a yellow guess [:p] (correct letter, wrong spot) is worth 5 points 
    # a black guess [:i] (wrong letter) is worth -1 points

    # it's likely the `game` object may need to be a global variable? 

    reward = 0.0 
    for letter in s 
        if letter == :c
            reward += 10.0
        elseif letter == :p
            reward += 5.0
        elseif letter == :i
            reward -= 1.0
        end
    end
    return reward
end

function wordle_init()
    # the initial state should be an empty game row
    return SparseCat([:i, :i, :i, :i, :i], [1.0])
end

function wordle()
    # construct and return the POMDP
    m = QuickPOMDP(
        states = wordle_states,
        actions = wordle_actions,
        observations = wordle_observations,
        transition = wordle_transition,
        observation = wordle_observation_probs,
        reward = wordle_reward,
        initialstate = wordle_init, 
        discount = 0.99
    )
    return m
end
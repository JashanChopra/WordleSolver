# This script defines Wordle as a POMDP for usage with the typical Julia libraries

using QuickPOMDPs: QuickPOMDP
using POMDPModelTools: Uniform, Deterministic
using Wordle
using Combinatorics
include("./helper.jl")

function wordle_states()
    # the total state space is the list of all valid words
    # :return: Vector{String}, a list of valid Wordle actions
    return deepcopy(Wordle.VALID_WORD_LIST)
end

function wordle_actions()
    # the total action space is the same as the state space, besides the empty word 
    # :return: Vector{String}, a list of valid Wordle actions
    return deepcopy(Wordle.VALID_WORD_LIST)
end

function wordle_observations()
    # I originally thought the observations should be what the return from a guess 
        # the number of letters correct, incorrect, or possibly correct 
        # however, when thinking about the observation probability, and the fact the 
        # the observation eseentially becomes the "state" 
        # I think the observation space is the same as the state space? 
    
    # :return: Vector{String}, a list of valid Wordle actions
    return deepcopy(Wordle.VALID_WORD_LIST)


    # # :output: observations: Array[Array[Symbol]]
    # # the observation comes from the Wordle.jl "WordleResponse" class 

    # # the wordle symbols correspond to the following:
    #     # Wordle.CORRECT : "green" guess
    #     # Wordle.PRESENT : "yellow" guess
    #     # Wordle.INCORRECT : "black" guess
    # # each state is an Array[Symbol] containing a symbol cooresponding to the guess type
    # # example: [Wordle.CORRECT, Wordle.PRESENT, Wordle.INCORRECT, Wordle.CORRECT, Wordle.INCORRECT]

    # # the total observation space is all possible 5-letter combinations of the set [Wordle.CORRECT, Wordle.PRESENT, Wordle.INCORRECT]
    
    # # construct all possible tuples 
    # # todo: how to do this efficiently, I'm so bad at Combinatorics 
    # N = 5
    # reverse.(Iterators.product(fill(0:N-1,N)...))[:]

    # # todo: this doesn't work
    # states = Array[]
    # start_set = [:c, :p, :i, :na1, :na2]
    # unique_sets = collect(with_replacement_combinations(start_set, 5))
    # for set in unique_sets 
    #     possibilities = collect(with_replacement_combinations(set, 5))
    #     for state in possibilities
    #         push!(states, state)
    #     end
    # end
    # final_states = unique(collect(states))
    # return final_states
end

function wordle_transition(s, a)
    # the state remains the same despite the action 

    # we could perhaps just include a default error rate 
        # something like we guess a totally different word 5% of the time? 
        # it doesn't really make physical sense though 

    return Deterministic(s)
end

function wordle_observation_probs(s, a, sp)
    # observation should be a function that takes in s, a, and sp, and returns the distribution of o
    
    # this function is theoretically fairly straightforward but it may be hard to implement 

    # from our observation, we can eliminate states that definately aren't the correct word
        # i.e: if our observation contains an "INCORRECT" observation for the letter "a" 
            # then any word with "a" in it can be eliminated 
        # once we've eliminated the correct words, there is a uniform probability of it being any remaining word
            # this is because the word is picked at random without any human input 
    words = deepcopy(Wordle.VALID_WORD_LIST)
    
    # the state is our target word (game.target)
    # the action is the word we guessed
    # the state_prime is also the target word, since our state never actually changes?

    leftover_possibilities = []
    Uniform(leftover_possibilities)
end

function wordle_reward(s, a)
    # :param: s: the current state
    # :param: a: the action, a Symbol object cooresponding to a 5 letter word from wordle_actions()

    # todo: we may have to adjust these rewards... they are not set in stone 

    # a green guess (letter is in the right spot) is worth 10 points 
    # a yellow guess (correct letter, wrong spot) is worth 5 points 
    # a black guess (wrong letter) is worth -1 points

    # the reward should be based on how close the current state  
        # and the chosen next state (the action) are to the correct word

    # i.e: the starting state has a reward of -5.0, because each letter is technically a "black" guess 
        # if we guess a starting word that has 1 correct letter, 1 present letter, and the rest wrong letters
        # then the reward for that action would be 10 + 5 - 3 = 12 
        # since we started with -5.0, our total reward should be 17
        # basically the action improved the state by "17 points"

    # there should also probably be some negative reward for how attempts it takes us 
        # which would mean we need to encode the number of attempts in the state

    # if we want to use the Wordle.CORRECT and other symbols, we need to include the "game" object 
    # in this function... which would mean it either has to be encoded in the state or it has to be a 
    # global variable 
end

function wordle_init()
    # the initial state should be a random word
    return Uniform(wordle_states())
end

function wordle(gamma=0.99)
    # construct a Wordle POMDP
    # :param: gamma: the discount factor

    # construct and return the POMDP
    m = QuickPOMDP(
        states = wordle_states,
        actions = wordle_actions,
        observations = wordle_observations,
        transition = wordle_transition,
        observation = wordle_observation_probs,
        reward = wordle_reward,
        initialstate = wordle_init, 
        discount = gamma
    )
    return m
end
# This script defines Wordle as a MDP for usage with the typical Julia libraries

using QuickPOMDPs: QuickPOMDP
using POMDPModelTools: Uniform, Deterministic
using Wordle
using Combinatorics
include("./helper.jl")

function words() 
    # return the word list
    return deepcopy(Wordle.VALID_WORD_LIST)
end

function wordle_states()
    # the total state space is the list of all valid words
    # along with the range of game turns (0-7)
    # 0 is the starting state, no guesses have been made 
    # if we get to turn 7, we failed the game
    # :return: Vector{Tuple(String, Int64)}, a list of valid Wordle actions
    turn_range = collect(0:7)        
    wordle_words = words()

    # create all possible tuples 
    states = Tuple{String, Int64}[]
    for t in turn_range
        for w in wordle_words
            push!(states, (w, t))
        end
    end
    return states

    # notes: 
        # if we wanted both of them to be Int64 we could construct a mapping of Int64 to the Wordle.VALID_WORD_LIST
        # not sure if this will be necesarry, storing the strings doesn't seem to be a big deal 
end

function wordle_actions()
    # the total action space is all the valid words, 
    # we have to make a guess each turn  
    # :return: Vector{String}, a list of valid Wordle actions
    return words
end

function wordle_observations()
    # :output: observations: Array[Array[Symbol]]
    # the observation comes from the Wordle.jl "WordleResponse" class 

    # the wordle symbols correspond to the following:
        # Wordle.CORRECT : "green" guess
        # Wordle.PRESENT : "yellow" guess
        # Wordle.INCORRECT : "black" guess
    # each state is an Array[Symbol] containing a symbol cooresponding to the guess type
    # example: [Wordle.CORRECT, Wordle.PRESENT, Wordle.INCORRECT, Wordle.CORRECT, Wordle.INCORRECT]

    # the total observation space is all possible 5-letter combinations of the set [Wordle.CORRECT, Wordle.PRESENT, Wordle.INCORRECT]
    
    # # construct all possible tuples 
    # # todo: how to do this efficiently, I'm so bad at Combinatorics 
    # N = 5
    # reverse.(Iterators.product(fill(0:N-1,N)...))[:]
    
    # the possible symbols 
    symbols = [:c, :p, :i]

    # get all possible 5 letter combinations of those three symbols 
    unique_sets = with_replacement_combinations(symbols, 5)

    # then, get all permutations of each of those combinations
    final_vec = []
    for set in unique_sets
        allperms = permutations(set, 5)
        for perm in allperms
            # push them to a single array 
            push!(final_vec, perm)
        end
    end
    final_obs = unique(final_vec)
    return final_obs
end

function wordle_transition(s, a)
    # transition function for Wordle, given the state and action 
    words_at_turn_zero = wordle_states[0:length(words())]
    if s[1] == a 
        # if we guess the correct word, reset the state 
        return Uniform(words_at_turn_zero)
    elseif s[2] == 7 
        # if we are on the 7th turn, reset the state
        return Uniform(words_at_turn_zero)
    else 
        # if we haven't guessed the word, and we have more turns left, the state remains the same
        return Deterministic(s)
    end
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
    if s[1] == a 
        # we found the word 
        return 100.0
    else
        # the loss is equal to the turn we are on
        return -1.0 * convert(Float64, s[2])
    end

    # notes: 
    # potentially old method of defining the reward function
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

    # Sunberg says: 
    # but if you add rewards heuristically based on your human intuition, 
    # it is easy to create a (PO)MDP with an optimal policy does not achieve 
    # optimal performance with respect to the original objective. For example, 
    # if you added a heuristic reward for always guessing e's since they are common, 
    # the algorithm might over-guess e's even when its probability of winning is higher with another letter.
end

function wordle_init()
    # the initial state is a random word at turn 0
    words_at_turn_zero = wordle_states[0:length(words())]
    return Uniform(words_at_turn_zero)
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

wordle_observations()
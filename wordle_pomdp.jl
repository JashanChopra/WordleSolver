# This script defines Wordle as a POMDP for usage with the typical Julia libraries

using QuickPOMDPs: QuickPOMDP
using POMDPModelTools: SparseCat
using Wordle

# I think the main decision we have to make here is should a state be a letter in the alphabet (a-z)
    # or should a state be a 5 letter word

# I think the 5 letter word way makes defining valid states easier, but then we essentially have a continuous distribution?
    # we could use the list of any valid word.... but I think it would be a more fun challenge to try to train an algorithim to not guess bogus words?

# if the states and actions are individual letters... then to construct a full guess we would essentially have to act! 5 times..
    # it would almost be like there would be 5 solvers running at the same time? idk how that would work 

# if the states and actions are full words, then our act! loop makes more sense but the state and action space is much larger?

function wordle_states()
    # get the list of all valid wordle words
    words = Wordle.VALID_WORD_LIST

    # convert each string in the list into symbols 
    states = Symbol[]
    for word in words 
        push!(states, Symbol(word))
    end
    return states
end

function wordle_actions()
    # for Wordle, the action space is the same as the state space 
    # i.e: a valid action is guessing a valid word 
    return wordle_states()
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

    # for now, just 100% chance of returning the state
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

    # a green guess (letter is in the right spot) is worth 10 points 
    # a yellow guess (correct letter, wrong spot) is worth 5 points 
    # a black guess (wrong letter) is worth -1 points

    # the wordle symbols coorespond to the following:
        # Wordle.CORRECT : "green" guess
        # Wordle.PRESENT : "yellow" guess
        # Wordle.INCORRECT : "black" guess

    # it's likely the `game` object may need to be a global variable? 
    word = string(a)
    response = guess(game, word).result

    reward = 0.0 
    for letter in response 
        if letter == Wordle.CORRECT
            reward += 10.0
        elseif letter == Wordle.PRESENT
            reward += 5.0
        elseif letter == Wordle.INCORRECT
            reward -= 1.0
        end
    end
    return reward
end

function wordle_init()
    # the initial state should be an empty game 
    # we will have to add an "empty" state to the states list 
    # or should the initial word just be a random word? 

    states = wordle_states() 
    word = rand(states, 1)
    return SparseCat(word, [1.0])
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
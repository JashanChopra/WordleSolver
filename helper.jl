# A series of helper wrapper functions for the Wordle.jl library  
using DataStructures: SortedSet

include("./wordlegame.jl")
include("./it_heuristic.jl")

function words() 
    # return the word list
    return deepcopy(Wordle.VALID_WORD_LIST)
end

function winning_policy(m, game, i)
    # a policy that always guesses the correct word 
    # :return: String, a Wordle guess
    return game.target
end

function random_policy(m, game, i)
    # a policy that returns a random action
    # :return: String, a Wordle guess
    return rand(actions(m))
end

function heuristic_policy(m, game, i)
    # a policy that guesses a random word from an eliminated list 
    # :return: String, a Wordle guess

    # get the possible word list 
    list = deepcopy(game.possible_word_list)

    # guess a random word from that list 
    guess = rand(list) 

    # remove impossible answers based on that guess for next time 
    new_list = get_possible_words(game.target, guess, list)
    game.possible_word_list = deepcopy(new_list)

    return guess 
end

function it_heuristic_wrapper(m, game, i) 
    # the information theory solver is pretty complex, so instead of requiring
    # a policy that guesses the word, we just preconstruct the guess list 
    # and then return that at eafh step
    i = convert(Int, i)

    # the first guess, fill out guesses using information theory 
    if i == 0
        guesses = it_solver(m, game)
        game.preguesses = deepcopy(guesses)
    end

    # on the last step we don't need a guess, avoid index error
    if i == 6 
        i = 5
    end

    # return the precalculated guesses
    return game.preguesses[i+1]
end

function create_random_game(sol_set = false)
    # :return: Wordlegame
    # create a random Wordle game 
    if sol_set 
        # choose from the solution set
        word = rand(VALID_SOLUTIONS_LIST, 1)[1]
    else
        # choose from the full set
        word = rand(Wordle.VALID_WORD_LIST, 1)[1]
    end
    
    return WordleGame(word)
end

function create_game(word)
    # create a Wordle game with the provided word
    # :param: word: String, a valid Wordle word
    # :return: Wordlegame
    return WordleGame(word)
end

function is_letter_in_word(letter, word) 
    # :param: letter: Char, a letter
    # :param: word: String, a word
    # :return: Bool, true if the letter is in the word, false otherwise
    return occursin(letter, word)
end

function is_letter_in_spot_in_word(letter, idx, word)
    # :param: letter: Char, a letter
    # :param: idx: Int, the index of the letter in the guesed word
    # :param: word: String, a word
    # :return: Bool, true if the letter is at spot idx in a word
    return word[idx] == letter
end

function get_results(word, guess) 
    # our logic for marking letters as Correct, Incorrect, or Present is similar to 
    # Wordle.guess but we don't delete Correctletters from the SortedSets so that 
    # we don't mark Present letters as Incorrect if there is a Correct response for 
    # the same letter

    # i.e if the target word is "WORLD" and the guess is "HELLO" the first "L" will 
    # be marked as INCORRECT. Which then results in us eliminating the correct word "WORLD"
    # The below code makes sure this scenario does not occur.

    results = [:i, :i, :i, :i, :i]
    for m in intersect(word, guess)
        # find the sets of positions for each matched letter
        target_positions = SortedSet(findall(m, word))
        guess_positions = SortedSet(findall(m, guess))

        # for each exactly matching position, mark the letter as correct and
        # remove the position from the position sets
        for correct_position in intersect(target_positions, guess_positions)
            results[correct_position] = :c
            delete!(target_positions, correct_position)  
            delete!(guess_positions, correct_position) 
        end

        # pair off the remainining positions and mark them as present
        for (_, guess_position) in zip(target_positions, guess_positions)
            results[guess_position] = :p
        end
    end

    # construct tuples with letter of the guess, the result, and it's position
    tuples = Tuple{Char, Symbol, Int64}[]
    for (idx, r) in enumerate(results) 
        push!(tuples, (guess[idx], r, idx))
    end

    return tuples
end

function get_possible_words(word, guess, word_list)
    # :param: word: String, a valid Wordle word
    # :param: guess: String, a valid Wordle word
    # :return: Vector{String}, a list of valid Worldle words
    
    # get tuples cooresponding to each letter and it's response
    tuples = get_results(word, guess) 
    
    # there are a few edge cases to consider: 
        # 1. if a letter is correct, and another instance if that letter appears, it will be incorrect 
            # in this case, we don't want to remove every word without the "incorrect" letter, because 
            # that would remove the correct word 
        # 2. the same case above will occur if the first letter is present, and only one instance of that 
            # letter appears in the target word

    # for each letter in the guess, remove words from the list
    list = deepcopy(words)
    for (letter, resp, idx) in tuples 
        skip = false

        # edge case 1 & 2
        if resp == :i 
            # skip if the letter is correct elsewhere
            for (l, r, i) in tuples 
                if l == letter 
                    if r == :c && i != idx 
                        skip = true 
                    elseif r == :p && i != idx 
                        skip = true 
                    end
                end
            end
        end

        # if our edge cases hit, we skip 
        if skip == true 
            continue 
        end

        if resp == :i 
            # if the response is incorrect, remove any word with that letter 
            list = filter!((w) -> ~is_letter_in_word(letter, w), list)
        elseif resp == :p
            # if the response is present, remove any word without that letter
            list = filter!((w) -> is_letter_in_word(letter, w), list)
        elseif resp == :c 
            # if the response is correct, remove any word without that letter in that exact spot
            list = filter!((w) -> is_letter_in_spot_in_word(letter, idx, w), list) 
        end
        prev_letter = letter
    end

    # the list should never be empty 
    if isempty(list)
        logging && println(word_list)
        logging && println(word)
        logging && println(guess)
        logging && println(tuples)
        throw(ArgumentError("List cannot be empty"))
    end

    return list
end

function evaluate_policy(m, policy, n, printtf=true, sol_set = false)
    # a framework for evaluating Wordle games 

    # :param: m: WordlePOMDP, the Wordle POMDP
    # :param: policy: Function, a function that returns a String of a valid Wordle guess
    # :param: n: Int, the number of games to simulate
    # :return: Float, the average reward over n games
    # :return: Int, the number of games that were correctly guessed

    correct = 0         # the number of games that were solved correctly
    total_score = 0.0   # the running score over all games 
    for i in 1:n
        game = create_random_game(sol_set) # create a random game 

        # the game score cooresponds to the number of tries: the higher the score, the worse the policy
        max_tries = 6.0 
        game_score = 0.0
        while game_score <= max_tries 
            # all policies must take in the WordlePOMDP and the WordleGame objects
            word = policy(m, game, game_score)
            game_score += 1.0

            # check if the word is correct
            if word == game.target
                correct += 1
                printtf && println("   Game ", i, " was correctly guessed in ", convert(Int, game_score), " guesses")
                printtf && println("   The correct word was: ", game.target)
                break
            end 
        end
        total_score += game_score
    end
    # return the average game reward and number correct            
    return total_score / n, correct 
end

function evaluate_hard_words()
    # see how the solver does against some particularly tricky words 
    hard_words = ["PIZZA", "WATCH"]
end

# # test various word elimiation
# word = "WORLD"
# guess = "HELLO"
# println(get_possible_words(word, guess))
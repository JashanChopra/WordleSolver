# A series of helper wrapper functions for the Wordle.jl library  
using Wordle 
using POMDPs: actions
using DataStructures: SortedSet

function words() 
    # return the word list
    # return deepcopy(Wordle.VALID_WORD_LIST)

    # for testing with a much smaller list 
    return deepcopy(["HELLO", "WORLD", "GUESS"])
end

function winning_policy(m, game)
    # a policy that always guesses the correct word 
    # :return: String, a Wordle guess
    return game.target
end

function random_policy(m, game)
    # a policy that returns a random action
    # :return: String, a Wordle guess
    return rand(actions(m))
end

function create_random_game()
    # :return: Wordlegame
    # create a random Wordle game 
    word = rand(Wordle.VALID_WORD_LIST, 1)[1]
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

function get_possible_words(word, guess)
    # :param: word: String, a valid Wordle word
    # :param: guess: String, a valid Wordle word
    # :return: Vector{String}, a list of valid Worldle words
    list = words()

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

    # for each letter in the guess, remove words from the list
    for (letter, resp, idx) in tuples 
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
    end

    # the list should never be empty 
    if isempty(list)
        throw(ArgumentError("List cannot be empty"))
    end

    return list
end

function evaluate_policy(m, policy, n)
    # a framework for evaluating Wordle games 

    # :param: m: WordlePOMDP, the Wordle POMDP
    # :param: policy: Function, a function that returns a String of a valid Wordle guess
    # :param: n: Int, the number of games to simulate
    # :return: Float, the average reward over n games
    # :return: Int, the number of games that were correctly guessed

    correct = 0         # the number of games that were solved correctly
    total_score = 0.0   # the running score over all games 
    for i in 1:n
        game = create_random_game() # create a random game 

        # the game score cooresponds to the number of tries: the higher the score, the worse the policy
        max_tries = 6.0 
        game_score = 0.0
        while game_score <= max_tries 
            # all policies must take in the WordlePOMDP and the WordleGame objects
            word = policy(m, game)
            game_score += 1.0

            # check if the word is correct
            if word == game.target
                correct += 1
                println("   Game ", i, " was correctly guessed in ", convert(Int, game_score), " guesses")
                println("   The correct word was: ", game.target)
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
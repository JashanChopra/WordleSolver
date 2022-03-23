# A series of helper wrapper functions for the Wordle.jl library  
using Wordle 
using POMDPs: actions

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

function get_possible_words()

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
        global game = create_random_game() # create a random game 

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
# A series of helper wrapper functions for the Wordle.jl library  
using Wordle 

function winning_policy(m, game)
    # a policy that always guesses the correct word 
    return game.target
end

function random_policy(m, game)
    # a policy that returns a random word
    return rand(Wordle.VALID_WORD_LIST, 1)[1]
end

function create_random_game()
    # create a random Wordle game 
    word = rand(Wordle.VALID_WORD_LIST, 1)[1]
    return WordleGame(word)
end

function create_game(word)
    # create a Wordle game with the provided word
    # word: String, a valid Wordle word 
    return WordleGame(word)
end

function evaluate_policy(m, policy, n)
    # a framework for evaluating Wordle games 

    # :param: m: WordlePOMDP, the Wordle POMDP
    # :param: policy: Function, a function that returns a String of a valid Wordle guess
    # :param: n: Int, the number of games to simulate
    # :return: Float, the average reward over n games
    # :return: Int, the number of games that were correctly guessed

    correct = 0         # the number of games that were solved correctly
    total_reward = 0.0  # the total reward for all games
    for i in 1:n
        game = create_random_game() # create a random game 
        max_tries = 6 
        curr_tries = 0  

        game_reward = 0.0
        while curr_tries <= max_tries 
            # evaluate a policy to get a word 
            word = policy(m, game)

            # guess that word
            response = guess(game, word).result  

            # calculate the reward for the specific guess
            reward = 0.0 
            r_correct = 10.0 
            r_present = 5.0 
            r_incorrect = -1.0
            for letter in response 
                if letter == Wordle.CORRECT
                    reward += r_correct
                elseif letter == Wordle.PRESENT
                    reward += r_present
                elseif letter == Wordle.INCORRECT
                    reward += r_incorrect
                end
            end

            # update the number of tries and the overall game reward
            curr_tries += 1
            game_reward += reward 

            # if all letters were correct, we've successfully guessed the word
            if reward == r_correct * 5.0
                correct += 1
                println("Game ", i, " was correctly gussed in ", curr_tries, " guesses")
                println("The correct word was: ", game.target)
                break
            end            
        end
        # for each game, we add the total game_reward divided by the number of tries 
        total_reward += game_reward / curr_tries
    end
    # return the average game reward and number correct            
    return total_reward / n, correct 
end
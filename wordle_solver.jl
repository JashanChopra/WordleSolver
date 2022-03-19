# This script defines different solvers for Wordle 


# for right now, just testing out some of the Wordle.jl library usage
    # it will be really nice to use this to help us out 
    # we will have to make some wrappers for it 

using Wordle

# we can define games manually:
    # this would be good for creating training data for a potental RL algorithim
    
words = Wordle.VALID_WORD_LIST              # get the list of all valid wordle words
word = rand(words, 1)[1]                    # choose a random word
game = WordleGame(word)                     # create a game

# we could then run simulations on actual past wordle games
game = WordleGame(1)
game = WordleGame(rand(1:200))      # there's more than 200 now I forget how many have been made


# run running simulations, there's some nice things we can use here: 
    # we can use guess! basically as a replacement for actually taking an action 
    # if we want to use the POMDP stuff, such as "act!" we will have to define a wrapper for it 
guess!(game, "guess")   # "guess" here would be replaced by the guess constructed by various algorithims

# we can use this to get a list of the letters that have been guessed 
    # if we seek to incorporate domain knowledge into an algorithim than this would help
    # i.e: we can make sure an algorithim doesn't guess the same wrong letter twice, 
        # or make sure that it uses correct guesses in the next guess 
print_available_letters(game)

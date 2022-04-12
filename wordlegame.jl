# redefine elements from the Wordle library 
using Wordle

# give the WorldeGame struct a field containing possible guesses 
mutable struct WordleGame
    target::String
    number::Union{Int, Nothing}
    guesses::Vector{Wordle.WordleGuess}
    hard::Bool
    possible_word_list::Vector{String}

    function WordleGame(target::String, number::Union{Int, Nothing} = nothing,
               guesses::Vector{Wordle.WordleGuess} = Wordle.WordleGuess[]; hard = false, 
               possible_word_list::Vector{String} = deepcopy(Wordle.VALID_WORD_LIST))

        target = lowercase(target)

        if target ∉ Wordle.VALID_WORD_LIST
            error("""Target word "$target" is not a valid word""")
        end

        if !isnothing(number) && !(0 < number <= LATEST_WORDLE_NUMBER)
            error("Given Wordle number is too large ($number).")
        end

        if length(guesses) > 6
            error("There are too many guesses ($(length(guesses))")
        end

        new(target, number, guesses, hard, possible_word_list)
    end
end
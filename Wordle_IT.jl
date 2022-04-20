using Wordle
using JSON
using Flux

function get_priors()

    prior_dict = JSON.parsefile("word_freq.txt")

    words = collect(keys(prior_dict))
    freq = [get(prior_dict,word,0.0) for word in words]

    sort_perm = sortperm(freq)
    sort_word = words[sort_perm]

    x_width = 10
    c = x_width * (-0.5 + 3000 / length(words))

    xs = LinRange(c - x_width / 2, c + x_width / 2, length(words))
    return freq_dict = Dict(word => sigmoid(x) for (word, x) in zip(sort_word, xs))

end

function calc_entropy(word_list::Vector{String},possible_word_list::Vector{String})
    entropy = Vector{Float64}(undef, length(word_list))
    fill!(entropy,0.0)
    iter = 0
    for guessed_word in word_list
        counts = Vector{Float64}(undef, 243)
        fill!(counts,0)
        iter += 1
        freq_sum = 0
        for valid_word in possible_word_list
            index = 1
            for c in 1:5
                if guessed_word[c] == valid_word[c]
                    index += 3^(5-c)*0
                elseif occursin(guessed_word[c], valid_word)
                    index += 3^(5-c)*1
                else
                    index += 3^(5-c)*2
                end
            end
            freq = get(freq_dict,valid_word,0.0)
            global counts[index] += freq
            freq_sum += freq
        end
        prob = counts./freq_sum
        global entropy[iter] = -sum((prob.*my_log2.(prob)))
    end
    return entropy
end

function parse_result(game::WordleGame, iteration::Int64)

    does_not_contain::String = ""
    contains::String = ""
    matches::Vector{Int64} = []
    does_not_match = Vector{String}(undef,5)
    fill!(does_not_match,"")

    for index = 1:5
        if game.guesses[iteration].result[index] == :⬛️
            does_not_contain = string(does_not_contain,game.guesses[iteration].guess[index])
        elseif game.guesses[iteration].result[index] == :🟨
            contains = string(contains,game.guesses[iteration].guess[index])
            does_not_match[index] = string(does_not_match[index],game.guesses[iteration].guess[index])
        elseif game.guesses[iteration].result[index] == :🟩
            push!(matches,index) 
        end
    end

    does_not_contain_mod = ""
    for c in does_not_contain
        if isdisjoint(c,contains) && isdisjoint(c,game.guesses[iteration].guess[matches])
            does_not_contain_mod = string(does_not_contain_mod,c)
        end
    end
    return does_not_contain_mod, contains, does_not_match, matches
end

function gen_new_list(game::WordleGame,prev_word_list::Vector{String},iteration::Int64,does_not_contain::String, contains::String, does_not_match::Vector{String}, matches::Vector{Int64})
    
    new_word_list::Vector{String} = []
    new_word_list_prob = Vector{Float64}(undef,length(word_list))
    fill!(new_word_list_prob,0.0)

    for word in prev_word_list
        if isdisjoint(word,does_not_contain)
            if all([isdisjoint(word[i],does_not_match[i]) for i in 1:5]) && length(intersect(word,contains)) == length(unique(contains))
                if all([word[i]==game.guesses[iteration].guess[i] for i in matches])
                    if all([word[i]!=game.guesses[iteration].guess[i] for i in setdiff([1,2,3,4,5],matches)])
                        push!(new_word_list,word)
                        new_word_list_prob[findfirst(x -> x == word,word_list)] = get(freq_dict,word,0.0)
                    end
                end
            end
        end
    end
    return new_word_list, new_word_list_prob./sum(new_word_list_prob)
end

function read_words_file(filename::String)::Vector{String}
    s = open(filename) do file
        read(file, String)
    end
    s = replace(s, '\"' => "")
    return split(s, ", ")
end

function my_log2(x::Float64)
    if x > 0.0
        return log2(x) 
    else
        return 0.0
    end
end

freq_dict = get_priors()
word_list_test = read_words_file("solutions.txt")
word_list = [word_list_test;read_words_file("options.txt")]

total_iterations = 0
solved = 0
counter = 0
for word in word_list_test
    global solved, total_iterations, word_list, word_list_test, counter
    counter += 1
    game = WordleGame(word)

    guess_word = "tares"
    new_word_list = word_list

    for iteration = 1:6

        total_iterations += 1
        guess!(game, guess_word)

        if game.target == guess_word
            solved += 1
            break
        end

        dnc,c,dnm,m = parse_result(game,iteration)
        new_word_list,new_word_list_freq = gen_new_list(game,new_word_list,iteration,dnc,c,dnm,m)
        entropy = calc_entropy(word_list,new_word_list)
 
        if maximum(new_word_list_freq) > 0.35 
            guess_word = word_list[argmax(new_word_list_freq)]
        elseif (length(new_word_list) == 1)
            guess_word = new_word_list[1]
        else
            guess_word = word_list[argmax(entropy)]
        end
    end

    if(counter % 20) == 0
        println(counter)
        println(total_iterations/counter)
        println(solved/counter)
        println(counter-solved)
        println("*********")
    end

end
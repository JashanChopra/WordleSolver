using Wordle
using IntervalSets
using ReinforcementLearning
using ReinforcementLearningZoo
using Statistics
using Flux
using Flux.Losses
using StableRNGs
using Distributions
using Plots 

alphabet = "abcdefghijklmnopqrstuvwxyz"
const NUMBER_OF_ALPHABETS = 26
const STATE_ELEMENTS_PER_ALPHABET = 5

steps_to_play = 1

word_list = Wordle.VALID_WORD_LIST[1:100]
hot_encoded_list = Array{UInt8,2}(undef,length(word_list),NUMBER_OF_ALPHABETS*5)
fill!(hot_encoded_list,0x0)

for word_index = 1:length(word_list)
    for index = 1:5
        hot_encoded_list[word_index,(index-1)*NUMBER_OF_ALPHABETS+findfirst(word_list[word_index][index],alphabet)] = 1
    end
end

Base.@kwdef mutable struct WordleEnv{A,R,S,ACT} <: AbstractEnv
    reward::R
    action_space::Space{Vector{ClosedInterval{A}}}
    state_space::Space{Vector{ClosedInterval{UInt8}}}
    state::Vector{S}
    done::Bool
    action::Vector{ACT}
    iteration::Int64
    game::WordleGame
end

function WordleEnv(;kwargs...)
    reward = 0.0
    iteration = 0
    action_space = Space([-15.0f0..15.0f0 for k in 1:26*5])
    state_space = Space([0x0..0x5 for k in 1:26*5])
    state = Vector{UInt8}(undef,26*5)
    action = Vector{Float32}(undef,26*5)
    #game = WordleGame(rand(word_list))
    game = WordleGame("aahed")

    env = WordleEnv(
        reward,
        action_space,
        state_space,
        state,
        true,
        action,
        iteration,
        game
    )
    reset!(env)
    env
end

function RLBase.reset!(env::WordleEnv{A,R}) where {A,R}
    #env.game = WordleGame(rand(word_list))
    env.game = WordleGame("aahed")
    env.state =  Array{UInt8,1}(undef,NUMBER_OF_ALPHABETS*STATE_ELEMENTS_PER_ALPHABET+1)
    fill!(env.state,0x1)
    env.state[131] = 0x0
    env.reward = 0.0
    env.action = Array{Float32,1}(undef,26*5)
    fill!(env.action,1.0)
    env.done = false
    env.iteration = 0
    nothing
end

function (env::WordleEnv)(a::Vector{Float32})
    @assert a in env.action_space
    env.action = a
    _step!(env, a)
end

function _step!(env::WordleEnv, a)

    guessed_word = word_list[findmax(softmax(hot_encoded_list*a))[2]]
    guess!(env.game, guessed_word);

    env.reward = -1
    env.state[131] += 0x1
    env.iteration += 1

    for index in 1:5
        alphabet_index = findfirst(env.game.guesses[env.iteration].guess[index],alphabet)
        if env.game.guesses[env.iteration].result[index] == :🟩
            env.state[STATE_ELEMENTS_PER_ALPHABET*(alphabet_index-1)+index] = 0x2
            env.reward += 5
            for all_index in setdiff(1:26,alphabet_index)
                env.state[STATE_ELEMENTS_PER_ALPHABET*(all_index-1)+index] = 0x0
            end
        elseif env.game.guesses[env.iteration].result[index] == :🟨
            env.state[STATE_ELEMENTS_PER_ALPHABET*(alphabet_index-1)+index] = 0x0
            env.reward += 2
        else
            for all_index in 1:5
                env.state[STATE_ELEMENTS_PER_ALPHABET*(alphabet_index-1)+all_index] = 0x0
            end
        end
    end

    if (env.iteration == 6 || guessed_word == env.game.target)
        if guessed_word != env.game.target
            env.reward = -20
        else
            env.reward = 20
        end
        
        env.done = true
    end
    nothing
end

RLBase.action_space(env::WordleEnv) = env.action_space
RLBase.reward(env::WordleEnv) = env.reward
RLBase.state(env::WordleEnv) = env.state
RLBase.state_space(env::WordleEnv) = env.state_space
RLBase.is_terminated(env::WordleEnv) = env.done

function RL.Experiment(
    ::Val{:JuliaRL},
    ::Val{:PPO},
    ::Val{:Wordle},
    ::Nothing;
    save_dir = nothing,
    seed = 123,
)
    rng = StableRNG(seed)
    ns = 131 
    na = 130

    UPDATE_FREQ = 32
    env = WordleEnv()
    
    agent = Agent(
        policy = PPOPolicy(
            approximator = ActorCritic(
                actor = GaussianNetwork(;
                    pre = Chain(
                        Dense(ns, 256,relu;init = glorot_uniform(rng)),
                        Dense(256, 256,relu;init = glorot_uniform(rng)),
                    ),
                    μ = Chain(Dense(256,130,sigmoid,init = glorot_uniform(rng)),vec,softmax),
                    logσ = Chain(Dense(256,130,x -> clamp(x, typeof(x)(0), typeof(x)(1)),init = glorot_uniform(rng)),vec)
                ),
                critic = Chain(
                    Dense(ns, 256, relu; init = glorot_uniform(rng)),
                    Dense(256, 256, relu; init = glorot_uniform(rng)),
                    Dense(256, 1; init = glorot_uniform(rng)),
                ),
                optimizer = ADAM(1e-3),
            ),
            γ = 1.0f0,
            λ = 0.95f0,
            clip_range = 0.4f0,
            max_grad_norm = 0.5f0,
            n_epochs = 4,
            n_microbatches = 32,
            actor_loss_weight = 1.0f0,
            critic_loss_weight = 0.5f0,
            entropy_loss_weight = 0.01f0,
            dist = Normal,
            rng = rng,
            update_freq = UPDATE_FREQ,
        ),
        trajectory = PPOTrajectory(;
            capacity = UPDATE_FREQ,
            state = Array{UInt8} => (ns,1,),
            action = Vector{Float32} => (na,1),
            action_log_prob = Vector{Float32} => (na,1),
            reward = Vector{Float64} => (1,),
            terminal = Vector{Bool} => (1,)
        ),
    )

    stop_condition = StopAfterStep(steps_to_play, is_show_progress=!haskey(ENV, "CI"))
    hook = TotalBatchRewardPerEpisode(1,is_display_on_exit = false)
    Experiment(agent, env, stop_condition, hook, "# Play Wordle with PPO")
end

ex = E`JuliaRL_PPO_Wordle`
run(ex)
mean(ex.hook.rewards[1])

avg_reward = Vector{Float64}(undef,length(ex.hook.rewards[1])-50)
fill!(avg_reward, 0.0)

for i in 51:length(ex.hook.rewards[1])
    avg_reward[i-50] = mean(ex.hook.rewards[1][i-50:i])
end

plot(-avg_reward, label=false,xlabel="Training Samples", ylabel="Score (Average Iterations)")

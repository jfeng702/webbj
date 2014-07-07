require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?
require 'pry'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

helpers do
  def calculate_total(cards) # cards is [['H', '2'], ['D', 'A',]...]
    arr = cards.map{|element| element[1]}

    total = 0

    arr.each do |a|
      if a == "A"
        total += 11
      elsif a.to_i == 0
        total += 10
      else total += a.to_i
      end
    end

    #correct for Aces
    arr.select{|element| element == 'A'}.count.times do
      if total <= BLACKJACK_AMOUNT
        break
      else
        total -= 10
      end
    end

    total
  end

  def card_image(card) #['H', '2']
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def loser!(msg)
    @show_hit_or_stay_buttons = false
    @show_replay_button = true
    @error = "<strong>#{session[:player_name]} lost!</strong> #{msg}"
  end

  def winner!(msg)
    @show_hit_or_stay_buttons = false
    @show_replay_button = true
    @success = "<strong>#{session[:player_name]} won!</strong> #{msg}"
  end

  def tie!(msg)
    @show_hit_or_stay_buttons = false
    @show_replay_button = true
    @success = "<strong>Tie game.</strong> #{msg}"
  end

end

before do
  @show_hit_or_stay_buttons = true


end

get '/' do 
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
  
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required."
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  # create a deck and put it in session
  suits = ['H', 'D', 'S', 'C']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle! #[['H', '2'], ['D', 'A',]...]

  # deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop


  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hits Blackjack!")

  elsif player_total > BLACKJACK_AMOUNT
    loser!("#{session[:player_name]} busted at #{player_total}!")
  end

  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit Blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busts at #{dealer_total}.")
  elsif dealer_total >= DEALER_MIN_HIT #17, 18, 19, 20
    #dealer stays
    redirect '/game/compare'
  else
    #dealer hits
    @show_dealer_hit_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  dealer_total = calculate_total(session[:dealer_cards])
  player_total = calculate_total(session[:player_cards])

  if dealer_total > player_total
    loser!("#{session[:player_name]} stayed at #{player_total}. Dealer stayed at #{dealer_total}.")
  elsif dealer_total == player_total
    tie!("#{session[:player_name]} tied with Dealer at #{player_total}")
  else
    winner!("#{session[:player_name]} stayed at #{player_total}. Dealer stayed at #{dealer_total}.")
  end

  erb :game
end

get '/game/replay' do
  redirect '/game'
end

get '/game/endgame' do
  "The end."
end
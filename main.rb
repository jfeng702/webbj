require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?
require 'pry'

set :sessions, true

get '/inline' do 
  "Sup Dawg"
end

get '/template' do
  erb :mytemplate
end

get '/nested_template' do
  erb :"/users/profile"
end
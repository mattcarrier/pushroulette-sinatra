require 'rubygems'
require 'bundler'

Bundler.require

require './app/pushroulette'

set :port, 4567

run Pushroulette

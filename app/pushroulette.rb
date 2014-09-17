require 'sinatra/base'
require './app/routes/github'
require './app/routes/jenkins'

class Pushroulette < Sinatra::Base
  use Github
  use Jenkins
end

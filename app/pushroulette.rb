require 'sinatra/base'
require './app/routes/github'
require './app/routes/jenkins'

module Pushroulette
  class App < Sinatra::Base

    use Pushroulette::Github
    use Pushroulette::Jenkins

  end
end

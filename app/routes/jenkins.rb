require './app/routes/base-route'

module Pushroulette
  class Jenkins < Pushroulette::BaseRoute

    get '/jenkins-hi' do
      'jenking says hi'
    end

  end
end

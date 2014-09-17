require 'json'
require './app/routes/base-route'

module Pushroulette
  class Github < Pushroulette::BaseRoute

    get '/hi' do
      "Hello World!"
    end

    post '/github/payload' do
      request.body.rewind  # in case someone already read it
      data = JSON.parse request.body.read
      puts data
      playClip(nil, true)
    end

    post '/store/clips' do
      params[:num].nil? ? downloadClips : downloadClips(params[:num].to_i)
    end

  end
end

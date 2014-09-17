require 'sinatra/base'
require './app/mixins/clips'

class Github < Sinatra::Base
  include Clips

  get '/hi' do
    "Hello World!"
  end

  post '/github/payload' do
    playClip(nil, true)
  end

  post '/store/clips' do
    puts params[:num]
    params[:num].nil? ? downloadClips : downloadClips(params[:num].to_i)
  end

end

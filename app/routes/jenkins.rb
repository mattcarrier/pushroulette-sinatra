require 'sinatra/base'

class Jenkins < Sinatra::Base

  get '/jenkins-hi' do
    'jenking says hi'
  end

end

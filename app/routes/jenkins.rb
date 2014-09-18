require './app/base/base'
require 'json'

module Pushroulette
  class Jenkins < Pushroulette::Base

    get '/jenkins-hi' do
      'jenking says hi'
    end

    post '/jenkins/job-finalized' do
      data = JSON.parse request.body.read
      failure_clip = @config['buildServer']['failureClip']
      clip_name =  failure_clip.kind_of?(Array) ? failure_clip.sample : failure_clip
      puts clip_name
      if data['build']['status'] == 'FAILURE'
        playClip("./app/clips/#{clip_name}.mp3", false)
      end
    end

  end
end

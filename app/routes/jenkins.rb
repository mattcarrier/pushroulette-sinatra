require './app/base/build-server-base'
require 'json'

module Pushroulette
  class Jenkins < Pushroulette::BuildServerBase

    get '/jenkins-hi' do
      'jenking says hi'
    end

    post '/jenkins/job-finalized' do
      data = JSON.parse request.body.read
      failure_clip = getFailureClip()

      playClip("./app/clips/#{failure_clip}.mp3", false) if jenkinsBuildFailed? data
    end

    def jenkinsBuildFailed?(data)
      data['build']['status'] == 'FAILURE'
    end

  end
end

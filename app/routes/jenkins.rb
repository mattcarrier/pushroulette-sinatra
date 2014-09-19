require './app/base/build-server-base'
require './app/models/build'
require 'json'

module Pushroulette
  class Jenkins < Pushroulette::BuildServerBase

    get '/jenkins-hi' do
      build = Pushroulette::Build.find_or_create(:build_key => 'test')
      build.status = 0
      build.save

      test_builds = Pushroulette::Build.where(:build_key => 'test').first
      puts 'all builds', test_builds.status
      'jenking says hi'
    end

    post '/jenkins/job-finalized' do
      data = JSON.parse request.body.read



      if jenkinsBuildFailed? data
        failure_clip = getFailureClip()
        playClip("./app/clips/#{failure_clip}.mp3", false)
        setPreviousBuildAsFailed(data['name'])

      elsif previousBuildFailed?(data['name'])
        back_to_normal_clip = getBackToNormalClip()
        playClip("./app/clips/#{back_to_normal_clip}.mp3", false)
        setPreviousBuildAsSuccessful(data['name'])
      end

    end

    def jenkinsBuildFailed?(data)
      status = data['build']['status']
      status == 'FAILURE' || status == 'UNSTABLE'
    end


  end
end

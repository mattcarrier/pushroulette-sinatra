require './app/base/base'

module Pushroulette
  class BuildServerBase < Pushroulette::Base

    def jenkinsBuildFailed?(data)
      data['build']['status'] == 'FAILURE'
    end

    def getFailureClip()
      failure_clip = @config['buildServer']['failureClip']
      failure_clip.kind_of?(Array) ? failure_clip.sample : failure_clip
    end


  end
end

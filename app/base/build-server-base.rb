require './app/base/base'
require './app/models/build'

module Pushroulette
  class BuildServerBase < Pushroulette::Base

    def getFailureClip()
      failure_clip = @config['buildServer']['failureClip']
      failure_clip.kind_of?(Array) ? failure_clip.sample : failure_clip
    end

    def previousBuildFailed?(build_key)
      build = Pushroulette::Build.find_or_create(:build_key => build_key)
      if build.status == 0
        return true
      else
        return false
      end
    end

    def setPreviousBuildAsFailed(build_key)
      build = Pushroulette::Build.find_or_create(:build_key => build_key)
      build.status = 0
      build.save
    end

    def setPreviousBuildAsSuccessful(build_key)
      build = Pushroulette::Build.find_or_create(:build_key => build_key)
      build.status = 1
      build.save
    end


  end
end

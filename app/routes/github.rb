require 'json'
require './app/base/base'

module Pushroulette
  class Github < Pushroulette::Base

    post '/github/payload' do
      request.body.rewind  # in case someone already read it
      data = JSON.parse request.body.read
      puts data
      playClip(nil, true)
    end

    def initialize(app)
      super
      @users = githubConfig('users')
      for user in @users
        genreClipDir = "/etc/pushroulette/library/#{user[genre]}"
        if (!(Dir.exists?(genreClipDir)) || !(Dir.glob("#{genreClipDir}/pushroulette_*.mp3").any?))
          downloadClips(5, user[genre])
        end
      end

      if !(Dir.glob("/etc/pushroulette/library/pushroulette_*.mp3").any?)
        downloadClips(5)
      end
    end

    def genreForUser(user)
      @users[user]['genre']
    end

    def githubConfig(config_key)
      pushrouletteConfig('github')[config_key]
    end
  end
end

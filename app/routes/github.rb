require 'json'
require 'fileutils'
require './app/base/base'

module Pushroulette
  class Github < Pushroulette::Base

    post '/github/payload' do
      request.body.rewind  # in case someone already read it
      data = JSON.parse request.body.read
      puts data
      user = @users[data['pusher']['name']]
      playClip(nil, true, user.nil? ? nil : user[genre])
    end

    post '/github/initialize' do
      Thread.new {
        @users = githubConfig('users')
        @users.each do |username, props|
          puts "username: #{username}"
          puts "props: #{props}"
          genreClipDir = "/etc/pushroulette-sinatra/library/#{props['genre']}"
          FileUtils::mkdir_p(genreClipDir)
          if 5 > Dir.glob("#{genreClipDir}/pushroulette_*.mp3").length
            downloadClips(5, props['genre'])
          end
        end

        if 5 > Dir.glob("/etc/pushroulette-sinatra/library/pushroulette_*.mp3").length
          downloadClips(5)
        end
      }
    end

    def genreForUser(user)
      @users[user]['genre']
    end

    def githubConfig(config_key)
      pushrouletteConfig('github')[config_key]
    end
  end
end

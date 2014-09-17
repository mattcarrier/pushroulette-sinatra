require 'sinatra/base'

module Pushroulette
  class BaseRoute < Sinatra::Base


    def initialize(app)
      super
      @client = SoundCloud.new(:client_id => 'cdbefc208d1db7a07c5af0e27e10b403')
    end

    def playClip(clip, deleteAfterPlay=false)
      played = false
      songs = 0;
      while !played do
        file = clip.nil? ? Dir.glob("/etc/pushroulette/library/pushroulette_*.mp3").sample : clip
        played = system "avplay -autoexit -nodisp #{file}" || !clip.nil?

        if deleteAfterPlay
          File.delete(file)
        end
        songs += 1
      end

      if clip.nil?
        downloadClips(songs)
      end
    end


    def downloadClips(num=1)
      i = 0
      while i < num do
        tracks = @client.get('/tracks', :q => 'downloadable', :limit => 50, :offset => [*0..8001].sample)
        for track in tracks
          if track.original_content_size < 10000000 and !track.download_url.nil?
            open('/etc/pushroulette/library/' + track.title + '.' + track.original_format, 'wb') do |file|
              file << open(track.download_url + '?client_id=cdbefc208d1db7a07c5af0e27e10b403', :allow_redirections => :all).read
              start = [*0..((track.duration / 1000) - 4)].sample
              sliceCreated = system "avconv -ss #{start} -i \"#{file.path}\" -t 5 /etc/pushroulette/library/pushroulette_#{SecureRandom.uuid}.mp3"
              File.delete(file)

              if !sliceCreated
                next
              end
            end

            i += 1
            if num >= i
              break
            end
          end
        end
      end
    end

  end
end

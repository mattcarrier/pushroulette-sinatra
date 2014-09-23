require 'sinatra/base'
require 'yaml'

module Pushroulette
  class Base < Sinatra::Base

    get '/hi' do
      "Hello World!"
    end

    post '/store/clips' do
      params[:num].nil? ? downloadClips : downloadClips(params[:num].to_i)
    end

    def initialize(app)
      super
      @client = SoundCloud.new(:client_id => 'cdbefc208d1db7a07c5af0e27e10b403')
      readConfigYaml
    end

    def readConfigYaml
      @config = YAML.load(File.open('./config.yaml'))
    end

    def pushrouletteConfig(config_key)
      @config['pushroulette'][config_key]
    end

    def playClip(clip, deleteAfterPlay=false, *genre)
      Thread.new {
        played = false
        songs = 0;
        if (genre.any?)
          dir = "/etc/pushroulette/library/#{genre.first}/"
        else
          dir = "/etc/pushroulette/library/"
        end
        while !played do
          file = clip.nil? ? Dir.glob("#{dir}pushroulette_*.mp3").sample : clip
          played = system "avplay -autoexit -nodisp #{file}" || !clip.nil?

          if deleteAfterPlay
            File.delete(file)
          end
          songs += 1
        end

        if clip.nil?
          downloadClips(songs)
        end
      }
    end


    def downloadClips(num=1, *genre)
      # @genres: cache for number of songs per genre
      if (@genres.nil?)
        @genres = Hash.new
      end

      # retrieve the number of songs per genre
      totalClips = 1000
      if (genre.any?)
        totalClips = @genres[genre.first]

        # find the number of songs per genre if not cached yet
        if (totalClips.nil?)
          begin
            totalClips = totalClips.nil? ? 1000 : (totalClips / 2).to_i
            puts totalClips
            tracks = @client.get('/tracks', :filter => 'downloadable', :limit => 50, :genres => genre.first.downcase, :offset => totalClips - 50)
          end while !tracks.any?

          if (1000 != totalClips and 50 == tracks.length)
            begin
              totalClips += 50
              puts totalClips
              tracks = @client.get('/tracks', :filter => 'downloadable', :limit => 50, :genres => genre.first.downcase, :offset => totalClips - 50)
              puts "tracks: #{tracks.length}"
            end while 0 < tracks.length and 50 > tracks.length
          end

          totalClips += tracks.length
          totalClips -= 50
          @genres[genre.first] = totalClips
        end
      end

      i = 0
      while i < num do
        if (genre.any?)
          dir = "/etc/pushroulette/library/#{genre.first}/"
          tracks = @client.get('/tracks', :filter => 'downloadable', :limit => 50, :genres => genre.first.downcase, :offset => [*0..totalClips].sample).shuffle
        else
          dir = "/etc/pushroulette/library/"
          tracks = @client.get('/tracks', :filter => 'downloadable', :limit => 50, :offset => [*0..8000].sample).shuffle
        end
        for track in tracks
          if track.original_content_size < 10000000 and !track.download_url.nil?

            open(dir + track.title + '.' + track.original_format, 'wb') do |file|
              file << open(track.download_url + '?client_id=cdbefc208d1db7a07c5af0e27e10b403', :allow_redirections => :all).read
              start = [*0..((track.duration / 1000) - 4)].sample
              sliceCreated = system "avconv -ss #{start} -i \"#{file.path}\" -t 5 #{dir}pushroulette_#{SecureRandom.uuid}.mp3"
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

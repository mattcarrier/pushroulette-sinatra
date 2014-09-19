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
      @config['pushroulette']
    end

    def playClip(clip, deleteAfterPlay=false, *genre)
      played = false
      songs = 0;
      if (genre.any?)
        dir = "/etc/pushroulette/library/#{genre.first}/"
      elsif
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
    end


    def downloadClips(num=1, *genre)
      i = 0
      while i < num do
        if (genre.any?)
          dir = "/etc/pushroulette/library/#{genre.first}/"
          tracks = @client.get('/tracks', :q => 'downloadable', :limit => 50, :genres => genre.first, :offset => [*0..8001].sample)
        elsif
          dir = "/etc/pushroulette/library/"
          tracks = @client.get('/tracks', :q => 'downloadable', :limit => 50, :offset => [*0..8001].sample)
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

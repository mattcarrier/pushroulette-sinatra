require 'sinatra/base'
require 'yaml'

module Pushroulette
  class Base < Sinatra::Base
    PUSHROULETTE_DIR = '/etc/pushroulette-sinatra'
    LIBRARY_DIR = "#{PUSHROULETTE_DIR}/library"

    module OS
      def OS.windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
      end

      def OS.mac?
       (/darwin/ =~ RUBY_PLATFORM) != nil
      end

      def OS.unix?
        !OS.windows?
      end

      def OS.linux?
        OS.unix? and not OS.mac?
      end
    end

    get '/hi' do
      "What's Up!"
    end

    post '/initialize' do
      Thread.new {
        num = params[:num].nil? ? 5 : params[:num].to_i
        puts @users
        @users.each do |username, props|
          puts "username: #{username}"
          puts "props: #{props}"
          genreClipDir = "#{LIBRARY_DIR}/#{props['genre']}"
          puts genreClipDir
          FileUtils::mkdir_p(genreClipDir)
          numClips = Dir.glob("#{genreClipDir}/pushroulette_*.mp3").length
          puts numClips
          if num > numClips
            downloadClips(num - numClips, props['genre'])
          end
        end

        numClips = Dir.glob("#{LIBRARY_DIR}/pushroulette_*.mp3").length
        if num > numClips
          downloadClips(num - numClips)
        end
      }
    end

    def initialize(app)
      super
      @client = SoundCloud.new(:client_id => 'cdbefc208d1db7a07c5af0e27e10b403')
      readConfigYaml
      @users = pushrouletteConfig('users')
    end

    def readConfigYaml
      @config = YAML.load(File.open('./config.yaml'))
    end

    def pushrouletteConfig(config_key)
      @config['pushroulette'][config_key]
    end

    def user(name)
      @users[name]
    end

    def speak(text)
      puts "speaking #{text}"
      system "say #{text}" if OS.mac?
      system "espeak #{text}" if OS.unix?
    end

    def playClip(clip, deleteAfterPlay=false, *genre)
      Thread.new {
        played = false
        songs = 0;
        dir = genre.any? ? "#{LIBRARY_DIR}/#{genre.first}/" : "#{LIBRARY_DIR}/"
        while !played do
          file = clip.nil? ? Dir.glob("#{dir}pushroulette_*.mp3").sample : clip
          played = system "avplay -autoexit -nodisp #{file}" || !clip.nil?

          if deleteAfterPlay
            File.delete(file)
          end
          songs += 1
        end

        if clip.nil?
          downloadClips(songs, genre.any? ? genre.first : nil)
        end
      }
    end


    def downloadClips(num=1, *genre)
      puts num
      puts genre
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
          puts "starting search for total clips"
          begin
            totalClips = totalClips.nil? ? 1000 : (totalClips / 2).to_i
            puts "total clips now: #{totalClips}"
            puts "genres: #{genre.first.downcase}"
            puts "offset: #{totalClips - 50}"
            tracks = @client.get('/tracks', :filter => 'downloadable', :limit => 50, :genres => genre.first.downcase, :offset => totalClips - 50)
            puts "got tracks back"
            puts "got back #{tracks.length}"
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
          dir = "#{LIBRARY_DIR}/#{genre.first}/"
          tracks = @client.get('/tracks', :filter => 'downloadable', :limit => 50, :genres => genre.first.downcase, :offset => [*0..totalClips].sample).shuffle
        else
          dir = "#{LIBRARY_DIR}/"
          tracks = @client.get('/tracks', :filter => 'downloadable', :limit => 50, :offset => [*0..8000].sample).shuffle
        end

        t = 0
        for track in tracks
          if track.original_content_size < 10000000 and !track.download_url.nil?
            puts "track[#{t}]"
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

          t += 1;
        end
      end
    end

  end
end

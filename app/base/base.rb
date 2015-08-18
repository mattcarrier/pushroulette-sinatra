require 'json'
require 'sinatra/base'
require 'yaml'
require 'mp3info'

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

    post '/speak' do
      request.body.rewind  # in case someone already read it
      data = JSON.parse request.body.read
      speak data['msg'] if !data['msg'].nil?
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

    def hipchatConfig(config_key)
      pushrouletteConfig('hipchat')[config_key]
    end

    def user(name)
      @users[name]
    end

    def postToHipchat(room, username, text)
      if !room.nil? and !username.nil? and !hipchatConfig('token') and hipchatConfig('token') != "yourtoken"
        begin
          client = HipChat::Client.new(hipchatConfig('token'))
          client[room].send(username, text)
        rescue
          puts "Error posting to hipchat"
        end
      end
    end

    def speak(text)
      puts "speaking #{text}"
      system "say \"#{text}\"" if OS.mac?
      system "espeak \"#{text}\"" if OS.linux?
    end

    def postSoundFileInfoToHipchat(file)
      begin
        Mp3Info.open("#{file}") do |mp3info|
          puts mp3info
        end

        hipchatMessage = 'Now playing: '
        Mp3Info.open("#{file}") do |mp3|
          if mp3.tag2 and mp3.tag2.TIT2
            hipchatMessage = hipchatMessage + mp3.tag2.TIT2 + '<br>'
          end

          if mp3.tag2 and mp3.tag2.TPE1
            hipchatMessage = hipchatMessage + mp3.tag2.TPE1 + '<br>'
          end

          hipchatMessage = hipchatMessage + '<a href="' + mp3.tag2.COMM + '">' + mp3.tag2.COMM + '</a>'
        end
        postToHipchat(hipchatConfig('room'), hipchatConfig('username'), hipchatMessage)
      rescue
        puts "Couldn't get mp3 info for #{file}"
      end
    end

    def playClip(clip, deleteAfterPlay=false, *genre, postToHipchat)
      Thread.new {
        played = false
        songs = 0;
        dir = genre.any? ? "#{LIBRARY_DIR}/#{genre.first}/" : "#{LIBRARY_DIR}/"
        while !played do
          file = clip.nil? ? Dir.glob("#{dir}pushroulette_*.mp3").sample : clip

          if postToHipchat
            postSoundFileInfoToHipchat(file)
          end

          puts clip
          played = system "avplay -autoexit -nodisp #{file}" || !clip.nil?
          puts played

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
              outfile = "#{dir}pushroulette_#{SecureRandom.uuid}.mp3"
              puts outfile
              sliceCreated = system "avconv -ss #{start} -i \"#{file.path}\" -t 10 #{outfile}"
              Mp3Info.open("#{outfile}") do |mp3|
                mp3.tag2.COMM = track.download_url + '?client_id=cdbefc208d1db7a07c5af0e27e10b403'
              end
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

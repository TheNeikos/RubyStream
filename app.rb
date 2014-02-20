require 'sinatra/base'
require 'thin'
require 'haml'
require 'sass'
require 'coffee-script'

require 'data_mapper'
require 'dm-serializer'

#DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite://#{File.expand_path File.dirname(__FILE__)}/db/db.sqlite")

require './lib/ruby-stream'


def run(opts)

  # Start he reactor
  EM.run do

    # define some defaults for our app
    server  = opts[:server] || 'thin'
    host    = opts[:host]   || '0.0.0.0'
    port    = opts[:port]   || '80'
    web_app = opts[:app]

    # create a base-mapping that our application will set at. If I
    # have the following routes:
    #
    #   get '/hello' do
    #     'hello!'
    #   end
    #
    #   get '/goodbye' do
    #     'see ya later!'
    #   end
    #
    # Then I will get the following:
    #
    #   mapping: '/'
    #   routes:
    #     /hello
    #     /goodbye
    #
    #   mapping: '/api'
    #   routes:
    #     /api/hello
    #     /api/goodbye
    dispatch = Rack::Builder.app do
      map '/' do
        run web_app
      end
    end

    # NOTE that we have to use an EM-compatible web-server. There
    # might be more, but these are some that are currently available.
    unless ['thin', 'hatetepe', 'goliath'].include? server
      raise "Need an EM webserver, but #{server} isn't"
    end

    # Start the web server. Note that you are free to run other tasks
    # within your EM instance.
    Rack::Server.start({
      app:    dispatch,
      server: server,
      Host:   host,
      Port:   port
    })


    EM.add_periodic_timer(1) do

      Thread.new {

        pl = RubyStream::Playlist.first(:active => true)
        pl.current_time =  pl.current_time + 1

        puts "Updating to #{pl.current_time}"

        RubyStream::WebsocketServer.instance.updateActiveTime(pl.current_time)

        if(pl.current_time > pl.items.first(:position => pl.current_video).length)
          
          pl.current_time = 0 
          pl.current_video =  pl.current_video + 1 
          puts "Updating to #{pl.current_time} and #{pl.current_video}"
        
          if( pl.current_video > pl.items.length)
            pl.current_video =  1
          end
          pl.save
        else
          pl.save!
        end
      }

    end

  end
end

module RubyStream

  class App < Sinatra::Base

    configure do

      set :public_folder, File.dirname(__FILE__) + '/static'

      set :port, 80

      set :threaded, false

      set :bind, "0.0.0.0"
    end

    get '/stylesheet.css' do
      scss :styles, style: :expanded
    end

    get '/view/:name' do
      haml params[:name].to_sym
    end

    get '/api/playlists' do
      RubyStream::Playlist.all.to_json(:relationships=>{:items => {}, :creator => {:only =>[:name,:id,:external_id]}}, :methods => [:total_time, :video_count])
    end

    post '/api/playlist/new' do
      begin 
        request.body.rewind
        user_creds = JSON.parse request.body.read

        user = RubyStream::User.auth(user_creds["user_id"], user_creds["user_authkey"])

        body RubyStream::Playlist.create(:name => user_creds["name"], :creator => user).serialize
      rescue RubyStream::AuthError
        status 400
        body "You are not authorized"
      end
    end

    post '/api/playlist/update' do
      begin 
        user = RubyStream::User.auth(params["user_id"], params["user_authkey"])

        RubyStream::Playlist.get(params[id]).update(:name => params["name"]).serialize
      rescue RubyStream::AuthError
        status 400
        body "You are not authorized"
      end
    end

    post '/api/user/login' do
      begin
        request.body.rewind
        user_creds = JSON.parse request.body.read
        RubyStream::User.login(user_creds["name"], user_creds["password"]).to_json
      rescue RubyStream::LoginError
        {error: "User could not be found or the password did not match."}.to_json
      end
    end

    post '/api/user/auth' do
      begin
        request.body.rewind
        user_creds = JSON.parse request.body.read
        RubyStream::User.auth(user_creds["user_id"], user_creds["user_authkey"]).to_json
      rescue RubyStream::LoginError
        {error: "User could not be found or the password did not match."}.to_json
      end
    end

    get '/api/playlist/:id' do
      RubyStream::Playlist.get(params["id"]).serialize
    end

    post '/api/playlist/:id/changeOrder' do
      begin 
        request.body.rewind
        user_creds = JSON.parse request.body.read
        user = RubyStream::User.auth(user_creds["user_id"], user_creds["user_authkey"])

        RubyStream::Playlist.get(params["id"]).items.first(:position => user_creds["startIndex"]+1).move(user_creds["newIndex"]+1)
      rescue RubyStream::AuthError
        status 403
        body "You are not authorized"
      end
    end

    post '/api/playlist/:id/update' do
      begin 
        request.body.rewind
        user_creds = JSON.parse request.body.read
        user = RubyStream::User.auth(user_creds["user_id"], user_creds["user_authkey"])

        playlist = RubyStream::Playlist.get(params["id"])
        playlist.update(:name => user_creds["name"])
        playlist.serialize
      rescue RubyStream::AuthError
        status 403
        body "You are not authorized"
      end
    end

    post '/api/playlist/:id/activate' do
      begin 
        request.body.rewind
        user_creds = JSON.parse request.body.read
        user = RubyStream::User.auth(user_creds["user_id"], user_creds["user_authkey"])

        playlist = RubyStream::Playlist.get(params["id"])
        playlist.update(:active => true, :current_time => 0)
        playlist.serialize
      rescue RubyStream::AuthError
        status 403
        body "You are not authorized"
      end
    end

    post '/api/playlist/:id/add' do
      begin 
        request.body.rewind
        user_creds = JSON.parse request.body.read
        user = RubyStream::User.auth(user_creds["user_id"], user_creds["user_authkey"])

        RubyStream::Playlist.get(params["id"]).addYoutubeVideo(user_creds["url"], user)
      rescue RubyStream::AuthError
        status 403
        body "You are not authorized"
      rescue RubyStream::InvalidUrlError => e
        status 400
        body e.message
      end
    end

    post '/api/playlist/:id/removeVideo/:video_id' do
      begin 
        request.body.rewind
        user_creds = JSON.parse request.body.read
        user = RubyStream::User.auth(user_creds["user_id"], user_creds["user_authkey"])

        RubyStream::PlaylistItem.first(:playlist_id => params["id"], :id => params["video_id"]).destroy
      rescue RubyStream::AuthError
        status 403
        body "You are not authorized"
      rescue RubyStream::InvalidUrlError => e
        status 400
        body e.message
      end
    end

    post '/api/playlist/:id/activateVideo/:video_id' do
      begin 
        request.body.rewind
        user_creds = JSON.parse request.body.read
        user = RubyStream::User.auth(user_creds["user_id"], user_creds["user_authkey"])

        item = RubyStream::PlaylistItem.first(:playlist_id => params["id"], :id => params["video_id"])

        item.playlist.current_video = item.position
        item.playlist.current_time = 0

        item.playlist.save
        item.save

      rescue RubyStream::AuthError
        status 403
        body "You are not authorized"
      rescue RubyStream::InvalidUrlError => e
        status 400
        body e.message
      end
    end

    get '/websocket' do

      if request.websocket?
        RubyStream::WebsocketServer.instance.handleSocket(request)
      end

    end

    get '/*' do
      haml :index, format: :html5
    end

  end

end


run app: RubyStream::App.new

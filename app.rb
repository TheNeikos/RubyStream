require 'sinatra'
require 'haml'
require 'sass'
require 'coffee-script'

require 'data_mapper'
require 'dm-serializer'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite://#{File.expand_path File.dirname(__FILE__)}/db/db.sqlite")

require './lib/ruby-stream'

set :public_folder, File.dirname(__FILE__) + '/static'

set :port, 80

set :bind, "0.0.0.0"

get '/stylesheet.css' do
  scss :styles, style: :expanded
end

get '/view/:name' do
  haml params[:name].to_sym
end

get '/api/playlists' do
  RubyStream::Playlist.all.to_json
end

post '/api/playlist/new' do
  begin 
    request.body.rewind
    user_creds = JSON.parse request.body.read

    user = RubyStream::User.auth(user_creds["user_id"], user_creds["user_authkey"])

    body RubyStream::Playlist.create(:name => user_creds["name"], :creator => user).to_json
  rescue RubyStream::AuthError
    status 400
    body "You are not authorized"
  end
end

post '/api/playlist/update' do
  begin 
    user = RubyStream::User.auth(params["user_id"], params["user_authkey"])

    RubyStream::Playlist.get(params[id]).update(:name => params["name"]).to_json
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
  RubyStream::Playlist.get(params["id"]).to_json(:relationships=>{:items => {}, :creator => {:include =>[:name,:id,:external_id]}})
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
  rescue InvalidUrlError => e
    status 400
    body e.message
  rescue Exception => e
    status 400
    body e.message
  end

  
end

get '/*' do
  haml :index, format: :html5
end

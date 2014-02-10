require 'sinatra'
require 'haml'
require 'sass'
require 'coffee-script'

require 'data_mapper'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite://#{File.expand_path File.dirname(__FILE__)}/db/db.sqlite")

require './lib/ruby-stream'

set :public_folder, File.dirname(__FILE__) + '/static'

set :port, 80

get '/stylesheet.css' do
  scss :styles, style: :expanded
end

get '/view/:name' do
  haml params[:name].to_sym
end


get '/playlists' do
  RubyStream::Playlist.all.to_json
end


post '/user/login' do
  begin
    request.body.rewind
    user_creds = JSON.parse request.body.read
    RubyStream::User.login(user_creds["name"], user_creds["password"]).to_json
  rescue RubyStream::LoginError
    {error: "User could not be found or the password did not match."}.to_json
  end
end


get '/*' do
  haml :index, format: :html5
end

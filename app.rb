require 'sinatra'
require 'haml'
require 'sass'
require 'coffee-script'

set :public_folder, File.dirname(__FILE__) + '/static'

get '/' do
  haml :index, format: :html5
end

get '/stylesheet.css' do
  scss :styles, style: :expanded
end

get '/view/:name' do
  haml params[:name].to_sym
end

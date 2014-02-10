require 'data_mapper'
require 'dm-migrations'

require './lib/ipb_board'

module RubyStream

  class Settings
    def self.[](key)
      unless @data
        @data = YAML.load_file('settings.yml')
      end
      @data[key]
    end
  end

  class Playlist
    include DataMapper::Resource

    property :id, Serial
    property :current_video, Integer, :default => 1
    property :current_time, Integer, :default => 0
    property :name, String

    belongs_to :creator, 'User'

    has n, :playlist_items

    def addYoutubeVideo(url)
      id = /\?v=(.+)&?/.match(url)[1]
      raise InvalidUrlError, "The URL provided did not have a recognizable id" unless id
      uri = URI.parse("https://www.googleapis.com/youtube/v3/videos?part=id%2Csnippet%2CcontentDetails&id=#{ id }&key=#{Settings["youtube_api_key"]}")
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      data = JSON.parse(http.request Net::HTTP::Get.new(uri.request_uri).body)["items"]
      raise UnknownVideoError, "The ID provided does not seem to be an accessible youtube video" unless data.length > 0
      data = data[0]
      length = /PT([0-9]+)M([0-9]+)S/.match(data["contentDetails"]["duration"])
      self.playlist_items.create({
        :carrier => "Youtube", 
        :carrier_id => id, 
        :length => length[1].to_i * 60 + length[2].to_i, 
        :name => data["snippet"]["title"], 
        :author => data["snippet"]["channelTitle"]
      })

    end

  end

  class PlaylistItem
    include DataMapper::Resource

    property :id, Serial
    property :carrier, String
    property :carrier_id, String
    property :length, Integer
    property :name, String
    property :author, String
    property :score_up, Integer
    property :score_down, Integer

    belongs_to :added_by, 'User'
    belongs_to :playlist
  end

  class LoginError < StandardError; end

  class User
    include DataMapper::Resource
    
    property :id, Serial
    property :external_id, Integer
    property :name, String
    property :display_name, String
    property :password_hash, String
    property :password_salt, String
    property :muted, Boolean, :default => false
    property :banned, Boolean, :default => false
    property :is_admin, Boolean, :default => false
    property :is_moderator, Boolean, :default => false
    property :login_hash, String, :default => lambda { |r,p| Digest::MD5.hexdigest("#{r.password_hash}+#{r.name}") }

    def self.login(name, password)
      user = User.first(:name => name)
      if user
        if user.password_hash == hash_password(user.password_salt, password)
          return user
        else
          raise LoginError
        end
      else
        user_data = IPBoard::API.getUser(name)
        if user_data["member_id"].to_s == "0"
          raise LoginError
        end

        hash = user_data["members_pass_hash"]
        salt = user_data["members_pass_salt"]  

        if hash == hash_password(salt, password)
          #we are logged in!
          user = User.new(:external_id => user_data["member_id"], :name => name, :password_hash => hash, :password_salt => salt, :display_name => user_data["members_display_name"])

          if Settings["ipboard_admin_groups"].to_s.split(',').include? user_data["member_group_id"]
            user.is_admin = true
            user.is_moderator = true
          end

          if Settings["ipboard_moderator_groups"].to_s.split(',').include? user_data["member_group_id"]
            user.is_moderator = true
          end

          user.save
          
          return user
        else
          raise LoginError
        end
      end
    end

    def self.hash_password(salt, password)
      Digest::MD5.hexdigest( "#{Digest::MD5.hexdigest(salt)}#{Digest::MD5.hexdigest(password)}" )
    end

  end


end

DataMapper.auto_upgrade!

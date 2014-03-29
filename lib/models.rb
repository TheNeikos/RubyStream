require 'data_mapper'
require 'dm-migrations'
require 'dm-is-list'

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

  class InvalidUrlError < StandardError; end
  class UnknownVideoError < StandardError; end

  class Playlist
    include DataMapper::Resource

    property :id, Serial
    property :current_video, Integer, :default => 1
    property :current_time, Integer, :default => 0
    property :name, String
    property :active, Boolean, :default => false

    belongs_to :creator, 'User'

    has n, :items, 'PlaylistItem' , :constraint => :destroy

    def addYoutubeVideo(url, user)
      id = /v=([^"&?\/ ]{11})/.match(url)[1]
      raise InvalidUrlError, "The URL provided did not have a recognizable id" unless id
      uri = URI.parse("https://www.googleapis.com/youtube/v3/videos?part=id%2Csnippet%2CcontentDetails&id=#{ id }&key=#{Settings["youtube_api_key"]}")
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      data = JSON.parse(http.request(Net::HTTP::Get.new(uri.request_uri)).body)["items"]
      raise UnknownVideoError, "The ID provided does not seem to be an accessible youtube video" unless data.length > 0
      data = data[0]
      length = /PT([0-9]+[^MS])?([0-9]+[^HS])?([0-9]+[^MH])?/.match(data["contentDetails"]["duration"])

      length = (length[3].to_i || 0) + (length[2].to_i || 0) * 60 + (length[1].to_i || 0) * 3600

      self.items.create({
        :carrier => "Youtube", 
        :carrier_id => id, 
        :length => length, 
        :name => data["snippet"]["title"], 
        :author => data["snippet"]["channelTitle"],
        :added_by => user
      }).save
    end

    def serialize
      to_json(:relationships=>{:items => {}, :creator => {:only =>[:name,:id,:external_id]}}, :methods => [:total_time, :video_count])
    end
    
    def total_time
      items.aggregate(:length.sum)
    end

    def video_count
      items.count
    end

    before :save do
      if self.active
        Playlist.all(:active => true, :id.not => self.id ).update(:active => false)
      end
    end

    before :save do
      unless dirty_attributes.size == 1 and not dirty_attributes[:current_time].nil? #Don't notify if it's just the time
        WebsocketServer.instance.updatePlaylist(self.id)
      end
    end


  end

  class PlaylistItem
    include DataMapper::Resource

    property :id, Serial
    property :carrier, String
    property :carrier_id, String
    property :length, Integer
    property :name, String, :length => 100
    property :author, String, :length => 100
    property :score_up, Integer, :default => 0
    property :score_down, Integer, :default => 0
    
    belongs_to :added_by, 'User'
    belongs_to :playlist

    is :list, :scope => :playlist_id

    default_scope(:default).update(:order => [:position.asc])

    after :save do
      WebsocketServer.instance.updatePlaylist(self.playlist.id)
    end

    after :destroy do
      WebsocketServer.instance.updatePlaylist(self.playlist.id)
    end

  end

  class LoginError < StandardError; end

  class AuthError < StandardError; end

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
    property :login_hash, String

    def self.login(name, password)
      user = User.first(:name => name)
      if user
        if user.password_hash == hash_password(user.password_salt, password)
          user.updateAuthHash!
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
          user.updateAuthHash!
          return user
        else
          raise LoginError
        end
      end
    end

    def self.hash_password(salt, password)
      Digest::MD5.hexdigest( "#{Digest::MD5.hexdigest(salt)}#{Digest::MD5.hexdigest(password)}" )
    end

    def self.auth(id, authkey)
      user = User.first(:id => id)
      unless user && user.login_hash == authkey
        raise AuthError
      end
      return user
    end

    def updateAuthHash!
      self.login_hash = Digest::MD5.hexdigest("#{password_hash}+#{name}+#{Random.rand(100000000)}")
      save
    end

  end

  class ChatMessage
    include DataMapper::Resource
    
    property :id, Serial
    property :message, String, :length => 1024
    property :time_added, DateTime, :default => lambda {|p,r| DateTime.now }

    property :deleted, ParanoidBoolean

    belongs_to :user

    after :create do
      WebsocketServer.instance.sendMessage self
    end

  end


end

DataMapper.auto_upgrade!

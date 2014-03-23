require 'sinatra-websocket'
require 'singleton'

module RubyStream

  class WebsocketServer
    include Singleton

    def initialize
      @sockets = []
    end

    def handleSocket(request)
      request.websocket do |ws|
        client = WebsocketClient.new ws
        ws.onopen do
          @sockets << client
          updateUserCount
        end
        ws.onclose do
          @sockets.delete(client)
          sendUserLeft(client.user) if client.user
          updateUserCount
        end
      end
    end 

    def sendChatHistory(client)

    end

    def sendToAll data
      @sockets.each { |s|
        s.ws.send(data.to_json)
      }
    end

    def updatePlaylist(id)
      @sendToAll {'action' => "reloadPlaylists", 'id' => id}
    end

    def updateActiveTime(time)
      @sendToAll {'action' => "updateTime", 'time' => time}
    end

    def sendMessage(msg)
      @sendToAll {'action' => "insertChatMessage", 'data' => msg.to_json( {:relationships=> {:user => {:only => [:name,:id,:external_id] } } } ) }
    end

    def sendUserJoined(user)
      @sendToAll {'action' => "insertUserJoined", 'data' => {:message => "#{user.name} has joined the Chat."}}
    end

    def sendUserLeft(user)
      @sendToAll {'action' => "insertUserLeft", 'data' => {:message => "#{user.name} has left the Chat."}}
    end

    def updateUserCount
      data = []
      anons = 0
      @sockets.each do |socket|
        if socket.user.nil?
          anons = anons + 1
        else
          data << socket.user.to_json(:only => [:name, :id, :external_id])
        end
      end

      @sendToAll {'action' => "updateUsers", 'data' => {users: data.uniq, anons:anons}}
    end
  end

  class WebsocketClient
    attr_reader :ws
    attr_accessor :user
    def initialize(ws)
      user = nil
      @ws = ws
      ws.onmessage do |msg|
        handleMessage(msg)
      end
    end

    def handleMessage(msg)
      message = JSON.parse(msg)
      puts message
      data = message["data"]
      action = ('handle_' + message['action']).to_sym

      return unless self.instance_methods(false).include?(action)

      self.send action, data # Actually call the method

    end


    def handle_auth data
      begin 
          self.user = User.auth(data["user_id"], data["user_authkey"])
          puts "Authenticated User: #{user.name}"

          WebsocketServer.instance.sendUserJoined user
          WebsocketServer.instance.updateUserCount
        end
    end

    def handle_chat_message data
      if self.user and (not self.user.muted or not self.user.banned)
        ChatServer.instance.handleChatMessage(self.user, data["message"])
      end
    end

  end

end





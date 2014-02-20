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
        end
        ws.onclose do
          @sockets.delete(client)
          sendUserLeft(client.user) if client.user
        end
      end
    end 

    def sendChatHistory(client)

    end

    def updatePlaylist(id)
      puts "Sending reload"
      @sockets.each { |s|
        s.ws.send({'action' => "reloadPlaylists", 'id' => id}.to_json)
      }
    end

    def updateActiveTime(time)
      @sockets.each { |s|
        s.ws.send({'action' => "updateTime", 'time' => time}.to_json)
      }
    end

    def sendMessage(msg)
      @sockets.each { |s|
        s.ws.send({'action' => "insertChatMessage", 'data' => msg.to_json({:relationships=>{:user => {:only =>[:name,:id,:external_id]}}})}.to_json)
      }
    end

    def sendUserJoined(user)
      @sockets.each { |s|
        s.ws.send({'action' => "insertUserJoined", 'data' => {:message => "#{user.name} has joined the Chat."}}.to_json)
      }
    end

    def sendUserLeft(user)
      @sockets.each { |s|
        s.ws.send({'action' => "insertUserLeft", 'data' => {:message => "#{user.name} has left the Chat."}}.to_json)
      }
    end
  end

  class WebsocketClient
    attr_reader :ws, :user
    def initialize(ws)
      @user = nil
      @ws = ws
      ws.onmessage do |msg|
        handleMessage(msg)
      end
    end

    def handleMessage(msg)
      message = JSON.parse(msg)
      puts message
      data = message["data"]
      case(message["action"])
      when "auth"
        begin 
          user = User.auth(data["user_id"], data["user_authkey"])
          puts "Authenticated User: #{user.name}"
          @user = user

          WebsocketServer.instance.sendUserJoined user
        end
      when "chat_message"
        if @user and (not @user.muted or not @user.banned)
          ChatServer.instance.handleChatMessage(@user, data["message"])
        end
      end
    end
  end

end

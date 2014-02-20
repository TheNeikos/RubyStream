
module RubyStream

  class ChatServer
    include Singleton
    def handleChatMessage(user, message)
      ChatMessage.create(:user => user, :message => message)
    end
  end

end

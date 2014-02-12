require "xmlrpc/client"
XMLRPC::Config::ENABLE_NIL_CREATE = true

module XMLRPC
  module Convert
    def self.boolean(str)
      case str
      when "0" then false
      when "1" then true
      when "" then false
      else
        raise "RPC-value of type boolean is wrong"
      end
    end
  end
end


module IPBoard
  class API
    class << self
      def initServerIfNotAlready
        return if @server
        @server = XMLRPC::Client.new "worldofequestria.com", "/interface/board/index.php"
      end

      def getUser(name)
        initServerIfNotAlready
        @server.call("fetchMember",{
          :api_key => RubyStream::Settings["ipboard_api_key"],
          :api_module => "ipb",
          :search_type => "username",
          :search_string => name
          })
      end
    end
  end
end

module ActiveImap
  class Connection
    def initialize(user, password, options = {})
      @imap = Net::IMAP.new(ActiveImap.config.server_host, ActiveImap.config.server_port, ActiveImap.config.server_ssl)
      @imap.authenticate('LOGIN', user, password)    
    end
    
    def logout_and_disconnect
      @imap.logout
      @imap.disconnect
    end
    
    def folders(options = {})
      imap = ActiveImap::Folder.all self
    end
    
    def fetchData *args
      @imap.fetch *args
    end
    
    # Send all calls not in this class to Net::IMAP
    def method_missing(method, *args)
      @imap.send(method, *args)
    end
  end
end
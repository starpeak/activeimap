module ActiveImap
  class Config
    attr_writer :charset, :separator # :nodoc:
    attr_writer :server_host, :server_port, :server_ssl # :nodoc:
    
    def initialize(&block) #:nodoc:
      configure(&block) if block_given?
    end
    
    def configure(&block)
      yield(self)
    end
    
    def server_host # :nodoc:
      @server_host ||= 'localhost'
    end
    
    def server_port # :nodoc:
      @server_port ||= 443
    end
    
    def server_ssl # :nodoc:
      @server_ssl ||= false
    end
    
    def charset #:nodoc:
      @charset ||= 'UTF-8'
    end
    
    def separator #:nodoc:
      @separator ||= '.'
    end
    
    def server=(options)
      if options[:host]
        @server_host = options[:host]
      end
      if options[:port]
        @server_port = options[:port]
      end
      if options[:ssl]
        @server_ssl = options[:ssl]
      end
    end
  end
end
module ActiveImap
  class BodyPart
    attr_accessor :message, :content_type, :content, :charset
    
    def initialize(message, options)
      @message = message
      @content_type = options[:content_type]
      @content = options[:content]
      @charset = options[:charset]
      
      puts @content
    end
  end
end
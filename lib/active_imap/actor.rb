module ActiveImap
  class Actor
    attr_accessor :name, :user, :host
    
    def initialize(options = {})
      @name = options[:name].gsub(/^"/, '').gsub(/"$/, '').strip
      @user = options[:user]
      @host = options[:host]
    end
    
    def email 
      "#{user}@#{host}"
    end
    
    def human(options={})
      name.blank? ? email : options[:format] and options[:format].to_sym == :short ? name : "#{name} <#{email}>"
    end
    
    def to_s
      human :format => :short
    end
  end
end
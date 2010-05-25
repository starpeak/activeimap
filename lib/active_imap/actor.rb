module ActiveImap
  class Actor
    attr_accessor :name, :user, :host
    
    def initialize(options = {})
      @name = options[:name]
      @user = options[:user]
      @host = options[:host]
    end
    
    def email 
      "#{user}@#{host}"
    end
    
    def human
      name.blank? ? email : "#{name} <#{email}>"
    end
    
    def to_s
      human
    end
  end
end
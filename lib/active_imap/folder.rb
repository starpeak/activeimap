module ActiveImap
  class Folder
    include ActiveModel::AttributeMethods
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    extend ActiveModel::Translation
    define_model_callbacks :create
              
    #define_attribute_methods [:title, :parent_id, :parent]          

    attr_writer :title
    attr_reader :attrs, :errors, :persisted, :connection
  
    def initialize(connection, options = {})
      @connection = connection
      attributes = options
      @mailbox = options[:mailbox] || nil
      @attrs = options[:attrs] || []
      @persisted = options[:persisted] || false      
      
      @errors = ActiveModel::Errors.new(self)
    end
  
    def ==(other)
      self.mailbox.to_s == other.mailbox.to_s
    end
    
    def self.all(connection, options = {})
      imap = ActiveImap::Folder.new connection
      folders = imap.children options
    end
      
    def self.first(connection, options = {})
      all(connection, options).first  
    end
  
    def self.from_mailbox(connection, mailbox)
      ActiveImap::Folder.new connection, :mailbox => mailbox.name, :attrs => mailbox.attr, :persisted => true
    end
  
    def self.find(connection, id, options = {})
      mailbox = ActiveImap::Folder.id_to_mailbox id
      
      ActiveImap::Folder.find_by_mailbox connection, mailbox, options
    end
  
    def self.find_by_mailbox(connection, mailbox_selector, options = {})  
      if mailbox_selector.include? '%'
        if list = connection.list('', mailbox_selector)
          folders = []
          list.each do |mailbox|
            folders << ActiveImap::Folder.from_mailbox(connection, mailbox)
          end
          folders.sort{|a,b| a.title <=> b.title}
        else
          []
        end
      else
        if list = connection.list('', mailbox_selector)
          ActiveImap::Folder.from_mailbox connection, list.first
        else
          nil
        end
      end
    end
    
    def persisted?
      @persisted ||= false
    end
    
    def save
      new_mailbox = "#{parent_path}#{title}"
      
      puts "ActiveImap: Rename #{mailbox} to #{new_mailbox}"
      
      unless mailbox == new_mailbox     
        @connection.rename mailbox, new_mailbox
        @mailbox = new_mailbox
        @parent = nil
      end
    end
    
    def attributes=(attribute_values)
      attribute_values.each do |key, value|
        case key.to_sym
        when :title
          @title = value
        when :parent
          @parent = value
        when :parent_id
          parent_id = value
        end
      end
    end
    
    def update_attributes(attribute_values)
      self.attributes = attribute_values
      save
    end
    
    def update_attribute(attribute, value)
      update_attributes attribute => value
    end
    
    def mailbox
       return @mailbox unless @mailbox.nil?

       if title.blank?
         @mailbox = ''
       else
         @mailbox = "#{parent_path}#{title}"
       end
     end  
    
    def id
      ActiveImap::Folder.mailbox_to_id(mailbox) if mailbox
    end
    
    def to_key
      persisted? ? [id] : nil
    end
    
    def to_s
      "#<ActiveImap::Folder:#{id}>"
    end
    
    def i18n_scope
      :activeimap
    end
    
    def parent
      return @parent if @parent
      if mailbox
        @parent = ActiveImap::Folder.find_by_mailbox(@connection, mailbox.split(ActiveImap.config.separator)[0..-2] * ActiveImap.config.separator)
      end
    end
  
    def parent_id
      parent.id if parent
    end
    
    def parent_id=(id)
      @parent = ActiveImap::Folder.find(@connection, id)
      @parent
    end
    
    def parent_path 
      parent.path unless parent.nil?
    end
    
    def title
      return @title if @title
      if @mailbox and @mailbox.split(ActiveImap.config.separator).size > 1
        @title = Net::IMAP.decode_utf7(@mailbox.split(ActiveImap.config.separator).last)
      elsif @mailbox
        @title = Net::IMAP.decode_utf7(@mailbox)
      end
    end
    
    def path    
      if @mailbox.blank?
         ''
      else
        "#{@mailbox}#{ActiveImap.config.separator}"
      end
    end
      
    def children(options = {})
      return @children if @children and not options[:force]
    
      @children = ActiveImap::Folder.find_by_mailbox(@connection, "#{path}%", options) 
    end
  
    def create(new_title)
      new_mailbox = "#{path}#{new_title}"
      if @connection.create(new_mailbox)
        ActiveImap::Folder.new @connection, :mailbox => new_mailbox, :title => new_title, :parent => self
      else
        false
      end
    end
  
    def destroy
      @connection.delete(@mailbox)
    end
  
    def select
      @connection.select(@mailbox)
    end
  
    # Messages related
  
    def message_counts
      status = @connection.status(@mailbox, ['MESSAGES', 'RECENT', 'UNSEEN'])
      {:total => status['MESSAGES'], :recent => status['RECENT'], :unseen => status['UNSEEN']}
    end

    def total_message_count
      @connection.status(@mailbox, ['MESSAGES'])['MESSAGES']
    end
  
    def recent_message_count
      @connection.status(@mailbox, ['RECENT'])['RECENT']
    end
  
    def unseen_message_count
      @connection.status(@mailbox, ['UNSEEN'])['UNSEEN']
    end
  
    def messages(options = {})
      order = ['ARRIVAL']
      conditions = ['ALL']
    
      if options[:order] 
        order = options[:order].to_s.split(',').map{|o| o.strip.upcase}
      end
    
      if options[:conditions] 
        conditions = options[:conditions].to_s.split(',').map{|o| o.strip.upcase}
      end
    
      messages = []
    
      select
      @connection.sort(order, conditions, ActiveImap.config.charset).each do |message_id|
        messages << ActiveImap::Message.find(self, message_id)
      end
      messages
    end
    
    def self.mailbox_to_id(mailbox)
      return mailbox.to_s.gsub(/./){|c| "%x" % c[0]}
    end
    
    def self.id_to_mailbox(id)
      return (id.reverse+'0').scan(/../).reverse.map{|c| c.reverse.hex.chr}*''
    end
  end
end
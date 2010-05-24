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
    attr_reader :id, :attrs, :errors, :persisted, :connection
  
    def initialize(connection, options = {})
      @connection = connection
      @id = options[:id] ||= ''
      @attrs = options[:attrs] ||= []
      @persisted = options[:persisted] ||= false
      attributes = options
      
      @errors = ActiveModel::Errors.new(self)
    end
  
    def ==(other_folder)
      self.id == other_folder.id
    end
    
    def self.all(connection, options = {})
      imap = ActiveImap::Folder.new connection
      folders = imap.children options
    end
      
    def self.first(connection, options = {})
      all(connection, options).first  
    end
  
    def self.from_mailbox(connection, mailbox)
      ActiveImap::Folder.new connection, :id => mailbox.name, :attrs => mailbox.attr, :persisted => true
    end
  
    def self.find(connection, id, options = {})  
      if id.include? '%'
        if list = connection.list('', id)
          folders = []
          list.each do |mailbox|
            folders << ActiveImap::Folder.from_mailbox(connection, mailbox)
          end
          folders.sort{|a,b| a.title <=> b.title}
        else
          []
        end
      else
        if list = connection.list('', id)
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
      new_id = Net::IMAP.encode_utf7("#{parent_path}#{title}")
      
      puts "Rename Folder #{id} to #{new_id}"
      
      unless id == new_id       
        @connection.rename id, new_id
        @id = new_id
        @parent = nil
      end
    end
    
    def attributes=(attribute_values)
      attribute_values.each do |key, value|
        case key
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
    
    def to_key
      persisted? ? [id.to_s.gsub('.','%2e')] : nil
    end
    
    def parent
      return @parent if @parent
      
      @parent = ActiveImap::Folder.find(@connection, id.split(ActiveImap.config.separator)[0..-2] * ActiveImap.config.separator)
    end
  
    def parent_id
      parent.id
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
      if id.split(ActiveImap.config.separator).size > 1
        @title = Net::IMAP.decode_utf7(id.split(ActiveImap.config.separator).last)
      else
        @title = Net::IMAP.decode_utf7(id)
      end
    end
    
    def path    
      if id.blank?
         ''
      else
        "#{id}#{ActiveImap.config.separator}"
      end
    end
  
    def id
      return @id unless @id.nil?
     
      if title.blank?
        @id = ''
      else
        @id = "#{parent_path}#{title}"
      end
    end
    
    def children(options = {})
      return @children if @children and not options[:force]
    
      @children = ActiveImap::Folder.find(@connection, "#{path}%", options) 
    end
  
    def create(new_title)
      new_id = "#{path}#{new_title}"
      if @connection.create(new_id)
        ActiveImap::Folder.new @connection, :id => new_id, :title => new_title, :parent => self
      else
        false
      end
    end
  
    def destroy
      @connection.delete(id)
    end
  
    def select
      @connection.select(id)
    end
  
    # Messages related
  
    def message_counts
      status = @connection.status(id, ['MESSAGES', 'RECENT', 'UNSEEN'])
      {:total => status['MESSAGES'], :recent => status['RECENT'], :unseen => status['UNSEEN']}
    end

    def total_message_count
      @connection.status(id, ['MESSAGES'])['MESSAGES']
    end
  
    def recent_message_count
      @connection.status(id, ['RECENT'])['RECENT']
    end
  
    def unseen_message_count
      @connection.status(id, ['UNSEEN'])['UNSEEN']
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
  end
end
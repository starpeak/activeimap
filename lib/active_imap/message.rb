module ActiveImap
  class Message
    require 'base64'
    require 'iconv'
    
    include ActiveModel::AttributeMethods
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    extend ActiveModel::Translation
    define_model_callbacks :create

    #attr_accessor :subject
    attr_reader   :id, :errors, :persisted, :folder, :connection
    
    def initialize(folder, options = {})
      @folder = folder
      @connection = @folder.connection
      @id = options[:id].to_i ||= ''
      @persisted = options[:persisted] ||= false
      
      @errors = ActiveModel::Errors.new(self)
    end
    
    def self.find(folder, id)
      ActiveImap::Message.new(folder, :id => id, :persisted => true)
    end
    
    def self.all(folder)
      folder.messages
    end
    
    def persisted?
      @persisted ||= false
    end
    
    def to_key
      persisted? ? [id] : nil
    end
    
    def folder=(folder)
      @connection.select(@folder.id)
      
      @folder = folder
    end
    
    def envelope
      return @envelope if @envelope
      
      if folder.select
        msg = @connection.fetch(id, "ENVELOPE")[0]
        envelope = msg.attr["ENVELOPE"]
        
        #puts msg
        
        @envelope = {
          :uid => ActiveImap::Rfc2047.decode(msg.attr["UID"]),
          :subject => ActiveImap::Rfc2047.decode(envelope.try(:subject)),
          :date => ActiveImap::Rfc2047.decode(envelope.try(:date)),
          #:internal_date => ActiveImap::Rfc2047.decode(msg.attr["INTERNALDATE"]),
          :size => @connection.fetch(id, "RFC822.SIZE")[0].attr["RFC822.SIZE"],
        }
        [:from, :to, :cc, :reply_to, :bcc, :sender].each do |field|
          @envelope[field] = []

          envelope_actors = envelope.try(field)
          
          if envelope_actors
            envelope_actors.each do |envelope_actor| 
              @envelope[field] << ActiveImap::Actor.new({
                :name => ActiveImap::Rfc2047.decode(envelope_actor.try(:name)),
                :user => ActiveImap::Rfc2047.decode(envelope_actor.try(:mailbox)),
                :host => ActiveImap::Rfc2047.decode(envelope_actor.try(:host))
              })
            end  
          end
        end
        
        return @envelope
      else
        raise "Folder could not be selected: #{@folder.id}"
      end
    end
    
    def subject
      envelope[:subject] 
    end
    
    
    def from
      envelope[:from]
    end
     
    def sender
      envelope[:sender]
    end
    
    def to
      envelope[:to]
    end
    
    def reply_to
      envelope[:reply_to]
    end
    
    def cc
      envelope[:cc]
    end
    
    def bcc
      envelope[:bcc]
    end
            
    def date
      begin
        Time.parse(envelope[:date])
      rescue
      end
    end
    
    def size
      envelope[:size]
    end
    
    # In Rails views you should use
    # number_to_human_size size
    # instead for internationalization
    def human_size
      count = 0
      n = size
      while n >= 1024 and count < 4
        n /= 1024.0
        count += 1
      end
      format("%.1f",n) + %w(B kB MB GB TB)[count]
    end
    
    def flags
      return @flags if @flags
      if @folder.select
        @flags = @connection.fetchData(id, "FLAGS")[0].try(:attr)["FLAGS"]
      else
        raise "Folder could not be selected: #{@folder.id}"
      end
    end
    
    def flagged?
      flags.include? :Flagged
    end
    
    def unseen?
      not flags.include? :Seen
    end
    
    def junk?
      flags.include? :JunkRecorded
    end
    
    def answered?
      flags.include? :Answered
    end
    
    def draft?
      flags.include? :Draft
    end
    
    def deleted?
      flags.include? :Deleted
    end
    
    def raw
      return @raw if @raw
      if @folder.select
        @raw = @connection.fetchData(id, "BODY[]")[0].try(:attr)["BODY[]"]
      else
        raise "Folder could not be selected: #{@folder.id}"
      end
    end
    
    def body
      return @body if @body
      if @folder.select
        @body = @connection.fetchData(id, "BODY[TEXT]")[0].try(:attr)["BODY[TEXT]"]
      else
        raise "Folder could not be selected: #{@folder.id}"
      end
    end
    
    def body_structure
      return @body_structure if @body_structure
      if @folder.select
        @body_structure = @connection.fetchData(id, "BODYSTRUCTURE")[0].try(:attr)["BODYSTRUCTURE"]
      else
        raise "Folder could not be selected: #{@folder.id}"
      end
    end
    
    def body_text
      body
    end
  end
end
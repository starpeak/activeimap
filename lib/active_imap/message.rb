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
        envelope_from = envelope.try(:from)[0]
        
        puts msg
        
        @envelope = {
          :uid => ActiveImap::Rfc2047.decode(msg.attr["UID"]),
          :subject => ActiveImap::Rfc2047.decode(envelope.try(:subject)),
          :date => ActiveImap::Rfc2047.decode(envelope.try(:date)),
          :internal_date => ActiveImap::Rfc2047.decode(msg.attr["INTERNALDATE"]),
          :size => @connection.fetch(id, "RFC822.SIZE")[0].attr["RFC822.SIZE"],
          :from_name => ActiveImap::Rfc2047.decode(envelope_from.try(:name)),
          :from_email => "#{ActiveImap::Rfc2047.decode(envelope_from.try(:mailbox))}@#{ActiveImap::Rfc2047.decode(envelope_from.try(:host))}",
          
        }
      else
        raise "Folder could not be selected: #{@folder.id}"
      end
    end
    
    def subject
      envelope[:subject] 
    end
    
    def from_name
      envelope[:from_name]
    end
    
    def from_email
      envelope[:from_email]
    end
    
    def from
      "#{from_name} <#{from_email}>"
    end
    
    # same as for from for sender, reply_to, to, cc, bcc
    
    def date
      begin
        Time.parse(envelope[:date])
      rescue
      end
    end
    
    def mail_size
      envelope[:size]
    end
    
    def body
      return @body if @body
      if @folder.select
        @body = @connection.fetchData(id, "BODY[TEXT]")[0].try(:attr)["BODY[TEXT]"]
      else
        raise "Folder could not be selected: #{@folder.id}"
      end
    end
    
    def body_text
      body
    end
  end
end
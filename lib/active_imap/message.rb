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
        
        # This is a quick workaround for Mail parsing the beginning of a
        # mail without multipart containing lines with spaces within the
        # header 
        
        mail_text = ''
        in_body = false
        @raw.split("\n").each do |l| 
          in_body = true if l.size <= 1
          mail_text += "#{l}\n" if not l.match(/^(\s)+$/) or in_body
        end
        @raw = mail_text
      else
        raise "Folder could not be selected: #{@folder.id}"
      end
    end
    
    private
    def parse_parts(part)
      if part.multipart?
        part.parts.each do |p|
          parse_parts(p)
        end
      else
        @body_parts << ActiveImap::BodyPart.new(
          self,
          :content_type => part.content_type, 
          :charset => part.charset,
          :content => part.body.decoded
        )
      end
    end
    
    public
    def body_parts
      return @body_parts if @body_parts
      @body_parts = []
      
      mail = Mail.new(raw)    
      parse_parts mail
      @html_content = mail.html_part
      @html_content = @html_content ? Iconv.iconv(ActiveImap::config.charset, @html_content.charset, @html_content.body.to_s) : ''
      @text_content = mail.text_part
      @text_content = @text_content ? Iconv.iconv(ActiveImap::config.charset, @text_content.charset, @text_content.body.to_s) : Iconv.iconv(ActiveImap::config.charset, @body_parts.first.charset, @body_parts.first.content)
      @body_parts
    end
    
    def html_content
      body_parts unless @html_content
      return @html_content 
    end
    
    def text_content
      body_parts unless @text_content
      return @text_content
      
      
      if body_parts.size > 1
        body_parts.each do |part|
          return Iconv.iconv(ActiveImap::config.charset, part.charset, part.content) if part.content_type.include? 'text/'
        end
        return 'No Text included'
      else
        return body_parts.first.content
      end
    end
    
  end
end
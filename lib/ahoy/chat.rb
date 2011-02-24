require 'rubygems'
require 'xmpp4r'

module Ahoy
  class Chat
    attr_reader :user, :contact
    attr_accessor :client
    protected :client, :client=
    
    def initialize(user, contact)
      @user = user
      @contact = contact
      @client = nil
      self.use_markdown = Ahoy.use_markdown
    end
    
    # May raise Ahoy::ContactOfflineError
    # 
    def start
      user.contact.resolve.getaddrinfo
      connect
    end
    
    # May raise Ahoy::ContactOfflineError
    # 
    def send(text)
      start unless client
      
      message = Jabber::Message.new(contact.name, text)
      message.type = :chat
      markdown(message) if markdown?
      begin
        client.send(message)
      rescue IOError
        connect
        retry
      end
      message
    end
    
    def on_reply(&block)
      start unless client
      client.delete_message_callback("on_reply")
      
      client.add_message_callback(0, "on_reply") do |message|
        block.call(message.body) if message.type == :chat
      end
    end
    
    def receive
      start unless client
      thread = Thread.current
      reply = nil
      
      client.add_message_callback(0, "receive") do |message|
        if message.type == :chat
          reply = message.body
          thread.run
        end
      end
      Thread.stop
      
      client.delete_message_callback("receive")
      reply
    end
    
    def close
      client.close
      self.client = nil
    end
    
    def use_markdown=(value)
      @use_markdown = value
      if value && !markdown_processor
        %W{rdiscount kramdown maruku bluecloth}.each do |lib|
          begin
            require lib
            break
          rescue LoadError
          end
        end
      end
    end
    
    def markdown?
      @use_markdown && markdown_processor
    end
    alias use_markdown markdown?
    
    private
    def connect
      contact.resolve
      
      self.client = Jabber::Client.new(Jabber::JID.new(user.name))
      @client.features_timeout = 0.001
      begin
        client.connect(contact.target, contact.port)
      rescue Errno::ECONNREFUSED
        raise Ahoy::ContactOfflineError.new("Contact Offline")
      end
    end
    
    def markdown(message)
      html = REXML::Element.new("html")
      html.add_attribute("xmlns", "http://www.w3.org/1999/xhtml")
      body = html.add_element("body")
      markdown = markdown_processor.new(message.body)
      body.add_element(REXML::Document.new(markdown.to_html))
      message.add_element(html)
    end
    
    def markdown_processor
      return RDiscount if defined?(RDiscount)
      return Kramdown::Document if defined?(Kramdown::Document)
      return Maruku if defined?(Maruku)
      return BlueCloth if defined?(BlueCloth)
    end
    
  end
end
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
    end
    
    # May raise Ahoy::ContactOfflineError
    # 
    def start
      user.contact.resolve.getaddrinfo
      connect
    end
    
    # May raise Ahoy::ContactOfflineError
    # 
    def send(message)
      start unless client
      
      message = Jabber::Message.new(contact.name, message)
      message.type = :chat
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
    
  end
end
require 'rubygems'
require 'xmpp4r'
require File.expand_path("#{File.dirname(__FILE__)}/xmpp4r_hack")

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
    
    def close
      client.close
      self.client = nil
    end
    
    private
    def connect
      contact.resolve
      
      self.client = Jabber::Client.new(Jabber::JID.new(user.name))
      sleep 0.5
      begin
        client.connect(contact.target, contact.port, user.contact.ip)
      rescue Errno::ECONNREFUSED
        raise Ahoy::ContactOfflineError.new("Contact Offline")
      end
    end
    
  end
end
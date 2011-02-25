require 'socket'
require 'rubygems'
require 'dnssd'

module Ahoy
  class User
    attr_reader :short_name, :location, :domain, :contacts
    attr_accessor :port, :flags, :interface, :contact
    
    def initialize(name, location="nowhere", domain="local.")
      @short_name = name
      @location = location
      @domain = domain
      
      @contacts = Ahoy::ContactList.new(self)
      @contact = nil
      
      @port = 5562
      @flags = 0
      @interface = DNSSD::InterfaceAny
    end
    
    def name
      "#{short_name}@#{location}"
    end
    
    def sign_in(status="avail", msg=nil)
      @registrar = DNSSD.register(
        name,
        Ahoy::SERVICE_TYPE,
        domain,
        port,
        txt_record(status, msg),
        flags.to_i,
        interface)
    end
    
    def contact
      sleep 0.01 until @contact
      @contact
    end
    
    def chat(contact)
      Ahoy::Chat.new(self, contact)
    end
    
    def listen
      sock = server.accept
      sock_domain, remote_port, remote_hostname, remote_ip = sock.peeraddr
      other = contacts.find do |contact|
        contact.ip_addresses.include?(remote_ip)
      end
      
      client = Jabber::Client.new(Jabber::JID.new(name))
      client.features_timeout = 0.001
      client.instance_variable_set(:@socket, sock)
      client.start
      client.accept_features
      client.instance_variable_set(:@keepaliveThread, Thread.new do
        Thread.current.abort_on_exception = true
        client.__send__(:keepalive_loop)
      end)
      
      chat = Ahoy::Chat.new(self, other)
      chat.instance_variable_set(:@client, client)
      chat
    end
    
    def on_chat(&block)
      Thread.new do
        while chat = listen
          Thread.new {block.call(chat)}
        end
      end
    end
    
    private
    def txt_record(status, msg)
      DNSSD::TextRecord.new(
       "txtvers" => 1,
       "port.p2pj" => port,
       "status" => status,
       "msg" => msg,
       "1st" => short_name)
    end
    
    def server
      @server ||= TCPServer.new("0.0.0.0", port)
    end
    
  end
end
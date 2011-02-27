require 'socket'
require 'rubygems'
require 'dnssd'

module Ahoy
  class User
    attr_reader :short_name, :location, :domain, :contacts
    attr_accessor :port, :flags, :interface, :contact
    
    # :call-seq: User.new(name, location="nowhere", domain="local.") -> user
    # 
    # Create a new Ahoy::User.
    # 
    # Location should be set to the bonjour/zeroconf hostname.
    # 
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
    
    # :call-seq: user.name -> string
    # 
    # The user's name, in name@location format.
    # 
    def name
      "#{short_name}@#{location}"
    end
    
    # :call-seq: user.sign_in(status="avail", msg=nil) -> user
    # 
    # Register user as 'on-line' and available to send/receive messages.
    # 
    def sign_in(status="avail", msg=nil)
      @registrar = DNSSD.register(
        name,
        Ahoy::SERVICE_TYPE,
        domain,
        port,
        txt_record(status, msg),
        flags.to_i,
        interface)
      self
    end
    
    # :call-seq: user.chat(contact) -> chat
    # 
    # Initiate a new chat session with contact.
    # 
    def chat(contact)
      Ahoy::Chat.new(self, contact)
    end
    
    # :call-seq: user.listen -> chat
    # 
    # Listen for an incoming chat. This method will block until a chat is
    # recieved.
    # 
    def listen
      socket = server.accept
      domain, port, hostname, ip = socket.peeraddr
      other = contacts.find do |contact|
        contact.ip_addresses.include?(ip)
      end
      Ahoy::Chat.new(self, other, socket)
    end
    
    # :call-seq: user.on_chat {|chat| block } -> thread
    # 
    # Set up block as a callback for when a chat is initiated by a contact.
    # 
    # This method does not block, but does return a thread, which can be joined
    # if you wish to block.
    # 
    def on_chat(&block)
      Thread.new do
        while chat = listen
          block.call(chat)
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
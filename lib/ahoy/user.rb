require 'socket'
require 'rubygems'
require 'dnssd'

module Ahoy
  
  # Ahoy::User represents us, or the current system, and is the entry point for
  # using the Ahoy library.
  # 
  # Send a message to a specific example:
  #   user = Ahoy::User.new("Ford")
  #   user.sign_in
  #   
  #   chat = user.chat(user.contacts[/Arthur/])
  #   chat.send("Don't panic")
  # 
  # Simple echo server:
  #   user = Ahoy::User.new("echo")
  #   user.sign_in
  #   
  #   user.on_chat do |chat|
  #     chat.on_reply do |reply|
  #       chat.send(reply)
  #     end
  #   end.join
  # 
  # 
  class User
    attr_reader :short_name, :location, :domain, :contacts
    attr_accessor :port, :flags, :interface
    
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
      
      @contacts = Ahoy::ContactList.new(name)
      
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
      chat = Ahoy::Chat.new(name, contact.name)
      chat.connect(contact.target, contact.port(true))
    end
    
    # :call-seq: user.listen -> chat
    # 
    # Listen for an incoming chat. This method will block until a chat is
    # recieved.
    # 
    def listen
      socket = server.accept
      domain, port, hostname, ip = socket.peeraddr
      Ahoy::Chat.new(name, contacts.find_by_ip(ip).name).connect(socket)
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
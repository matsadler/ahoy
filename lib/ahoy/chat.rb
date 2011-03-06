require 'rubygems'
require 'xmpp4r'

module Ahoy
  
  # Ahoy::Chat models a conversation between the user and one of their contacts.
  # It can be thought of as representing an iChat chat window, or treated more
  # like a Ruby socket.
  # 
  class Chat
    attr_reader :user_name, :contact_name
    
    # :call-seq: Chat.new(user_name, contact_name) -> chat
    # 
    # Create a new Ahoy::Chat.
    # 
    def initialize(user_name, contact_name)
      @user_name = user_name
      @contact_name = contact_name
      @client = nil
      self.use_markdown = Ahoy.use_markdown
    end
    
    # :call-seq: chat.connect(target, port) -> chat
    # chat.connect(socket) -> chat
    # 
    # Connect to target on port, or use the connection provided by socket.
    # 
    def connect(host, port=nil)
      if host.respond_to?(:read) && host.respond_to?(:write)
        connect_with(host)
      else
        begin
          client.connect(host, port)
        rescue Errno::ECONNREFUSED
          raise Ahoy::ContactOfflineError.new("Contact Offline")
        end
      end
      self
    end
    
    # :call-seq: chat.connected? -> bool
    # 
    def connected?
      client.is_connected?
    end
    
    # :call-seq: chat.send(string) -> message
    # 
    # Send string to contact. May raise Ahoy::ContactOfflineError.
    # 
    def send(text)
      raise Ahoy::NotConnectedError.new("Not Connected") unless connected?
      
      message = Jabber::Message.new(contact_name, text)
      message.type = :chat
      markdown(message) if markdown?
      client.send(message)
      message
    end
    
    # :call-seq: chat.on_reply {|string| block }
    # 
    # Set up block as a callback for when a message is received.
    # 
    def on_reply(&block)
      client.delete_message_callback("on_reply")
      
      client.add_message_callback(0, "on_reply") do |message|
        block.call(message.body) if message.type == :chat
      end
    end
    
    # :call-seq: chat.receive -> string
    # 
    # Block until a message is received, then return the message body as a
    # string.
    # 
    def receive
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
    
    # :call-seq: chat.close -> nil
    # 
    # End the chat.
    # 
    def close
      client.close
      @client = nil
    end
    
    # :call-seq: chat.use_markdown = bool -> bool
    # 
    # Set true to send a html copy of messages, by interpreting the message text
    # as markdown.
    # 
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
      value
    end
    
    # :call-seq: chat.markdown? -> bool
    # 
    # Are messages sent to this chat being interpreted as markdown?
    # 
    def markdown?
      @use_markdown && markdown_processor
    end
    alias use_markdown markdown?
    
    private
    def connect_with(socket)
      client.instance_variable_set(:@socket, socket)
      client.start
      client.accept_features
      client.instance_variable_set(:@keepaliveThread, Thread.new do
        Thread.current.abort_on_exception = true
        client.__send__(:keepalive_loop)
      end)
    end
    
    def client
      return @client if @client
      @client = Jabber::Client.new(Jabber::JID.new(user_name))
      @client.features_timeout = 0.001
      @client
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
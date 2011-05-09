require File.expand_path("#{File.dirname(__FILE__)}/../ahoy")

module Ahoy
  
  # Ahoy::Broadcast provides a simple interface to send a message to all online
  # users. Example:
  #   user = Ahoy::User.new("Dr. Nick")
  #   cast = Ahoy::Broadcast.new(user)
  #   
  #   cast.send("Hi, everybody!")
  #   cast.close
  # 
  class Broadcast
    
    # :call-seq: Broadcast.new(user) -> broadcast
    # 
    # Create a new Ahoy::Broadcast.
    # 
    def initialize(user)
      user.sign_in
      sleep 1
      @chats = user.contacts.map {|cont| user.chat(cont) rescue nil}.compact!
    end
    
    # :call-seq: broadcast.send(string) -> array
    # 
    # Send string to all online contacts.
    # 
    def send(message)
      @chats.each do |chat|
        begin
          chat.send(message)
        rescue
          @chats.delete(chat)
        end
      end
    end
    
    # :call-seq: broadcast.close -> close
    # 
    # End all chats.
    # 
    def close
      @chats.each {|chat| chat.close}
    end
  end
end
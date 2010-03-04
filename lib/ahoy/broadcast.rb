require File.expand_path("#{File.dirname(__FILE__)}/../ahoy")

module Ahoy
  class Broadcast
    def initialize(user)
      user.sign_in
      sleep 1
      @chats = user.contacts.map {|contact| user.chat(contact)}
    end
    
    def send(message)
      @chats.each do |chat|
        begin
          chat.send(message)
        rescue
          @chats.delete(chat)
        end
      end
    end
    
    def close
      @chats.each {|chat| chat.close}
    end
  end
end
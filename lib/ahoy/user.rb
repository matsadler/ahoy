require 'rubygems'
require 'dnssd'

module Ahoy
  class User
    attr_reader :short_name, :location, :domain, :contacts
    attr_accessor :port, :flags, :interface, :contact
    
    def initialize(name, location="nowhere", domain="local")
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
    
    private
    def txt_record(status, msg)
      DNSSD::TextRecord.new(
       "txtvers" => 1,
       "port.p2pj" => port,
       "status" => status,
       "msg" => msg,
       "1st" => short_name)
    end
    
  end
end
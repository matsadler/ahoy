require 'rubygems'
require 'dnssd'

module Ahoy
  
  # Ahoy::Contact represents another user or system, available to recieve
  # messages, or who may send them to our user.
  # 
  class Contact
    attr_reader :name, :domain
    attr_accessor :online
    
    # :call-seq: Contact.new(name, domain="local.") -> contact
    # 
    # Create a new Ahoy::Contact. name should be in name@location format.
    # 
    def initialize(name, domain="local.")
      @name = name
      @domain = domain
      @target = nil
      @port = nil
      @interface_addresses = {}
      @online = true
    end
    
    # :call-seq: contact.fullname -> string
    # 
    # Returns the contact's full name in name@location.service.domain format
    # 
    def fullname
      [name, Ahoy::SERVICE_TYPE, domain].join(".")
    end
    
    # :call-seq: contact.target -> string
    # 
    # Return the contact's target attribute. Pass true as the argument to use
    # the cached value rather than looking it up.
    # 
    def target(use_cache=nil)
      resolve(use_cache)
      @target
    end
    
    # :call-seq: contact.port -> string
    # 
    # Return the contact's port attribute. Pass true as the argument to use
    # the cached value rather than looking it up.
    # 
    def port(use_cache=nil)
      resolve(use_cache)
      @port
    end
    
    # :call-seq: contact.interfaces -> array
    # 
    # Return the contact's interfaces. Pass true as the argument to use the
    # cached value rather than looking it up.
    # 
    def interfaces(use_cache=nil)
      resolve(use_cache)
      @interface_addresses.keys
    end
    
    # Internal use only.
    # 
    def add_interface(name) # :nodoc:
      @interface_addresses[name] = [] unless @interface_addresses.key?(name)
    end
    
    # :call-seq: contact.ip_addresses(interface=nil)
    # 
    # Returns all of contact's IP addresses, or if an interface is supplied as
    # an argument, just the IP addresses for that interface.
    # 
    # Pass true as the second argument to prevent a lookup of interfaces, pass
    # true as the third argument to prevent a lookup of IP addresses, and
    # instead use the cached value.
    # 
    def ip_addresses(interface=nil, resolve_cache=nil, use_cache=nil)
      getaddrinfo(resolve_cache) unless use_cache
      if interface
        @interface_addresses[interface]
      else
        @interface_addresses.values.flatten
      end
    end
    
    # :call-seq: contact == other_contact -> bool
    # 
    # Equality. Two contacts are equal if they have the same fullname (and
    # therefore name, location, service, and domain).
    # 
    def ==(other)
      other.is_a?(self.class) && other.fullname == fullname
    end
    
    # :call-seq: contact.online? -> bool
    # 
    # Is contact online?
    # 
    def online?
      online
    end
    
    # :call-seq: contact.resolve -> contact
    # 
    # Determine and set the contact's target, port, and interfaces.
    # 
    def resolve(use_cache=nil)
      if use_cache && @target && @port && @interface_addresses.keys.any?
        return self
      end
      service = DNSSD::Service.new
      main = Thread.current
      @interface_addresses.clear
      service.resolve(name, Ahoy::SERVICE_TYPE, domain) do |resolved|
        @target = resolved.target
        @port = resolved.port
        @interface_addresses[resolved.interface] = []
        unless Ahoy::more_coming?(resolved)
          service.stop unless service.stopped?
          main.run
        end
      end
      Thread.stop unless service.stopped?
      self
    end
    
    # :call-seq: contact.getaddrinfo(interface=nil) -> self
    # 
    # Determine and set the contact's IP addresses. If an interface is passed,
    # only lookup the IP addresses for that interface.
    # 
    # Pass true as the second argument to prevent a resolve.
    # 
    def getaddrinfo(interface=nil, resolve_cache=nil)
      unless interface
        interfaces(resolve_cache).each {|inter| getaddrinfo(inter, true)}
        return self
      end
      service = DNSSD::Service.new
      main = Thread.current
      service.getaddrinfo(target(resolve_cache), 0, 0, interface) do |addressed|
        @interface_addresses[addressed.interface].push(addressed.address)
        unless Ahoy::more_coming?(addressed)
          service.stop unless service.stopped?
          main.run
        end
      end
      Thread.stop unless service.stopped?
      self
    end
    
  end
end
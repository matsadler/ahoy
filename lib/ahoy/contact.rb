require 'rubygems'
require 'dnssd'

module Ahoy
  class Contact
    attr_reader :name, :domain
    attr_accessor :online
    
    def initialize(name, domain="local.")
      @name = name
      @domain = domain
      @target = nil
      @port = nil
      @interface_addresses = {}
      @online = true
    end
    
    def fullname
      [name, Ahoy::SERVICE_TYPE, domain].join(".")
    end
    
    def target(use_cache=nil)
      resolve(use_cache)
      @target
    end
    
    def port(use_cache=nil)
      resolve(use_cache)
      @port
    end
    
    def interfaces(use_cache=nil)
      resolve(use_cache)
      @interface_addresses.keys
    end
    
    def add_interface(name)
      @interface_addresses[name] = [] unless @interface_addresses.key?(name)
    end
    
    def ip_addresses(interface=nil, resolve_cache=nil, use_cache=nil)
      getaddrinfo(resolve_cache) unless use_cache
      if interface
        @interface_addresses[interface]
      else
        @interface_addresses.values.flatten
      end
    end
    
    def ==(other)
      other.is_a?(self.class) && other.fullname == fullname
    end
    
    def online?
      online
    end
    
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
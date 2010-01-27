require 'rubygems'
require 'dnssd'

module Ahoy
  class Contact
    attr_reader :name, :domain, :target, :ip, :port, :interface
    attr_accessor :online
    
    def initialize(name, domain="local")
      @name = name
      @domain = domain
      @target = nil
      @ip = nil
      @port = nil
      @interface = nil
      @online = true
    end
    
    def fullname
      [name, Ahoy::SERVICE_TYPE, domain].join(".")
    end
    
    def ==(other)
      other.is_a?(self.class) && other.fullname == fullname
    end
    
    def online?
      online
    end
    
    def resolve
      service = DNSSD::Service.new
      main = Thread.current
      service.resolve(name, Ahoy::SERVICE_TYPE, domain) do |resolved|
        next if Ahoy::more_coming?(resolved)
        service.stop unless service.stopped?
        @target = resolved.target
        @port = resolved.port
        @interface = resolved.interface
        main.run
      end
      Thread.stop unless service.stopped?
      self
    end
    
    def getaddrinfo
      service = DNSSD::Service.new
      main = Thread.current
      service.getaddrinfo(target, DNSSD::Service::IPv4, 0, interface) do |addressed|
        service.stop unless service.stopped?
        @ip = addressed.address
        main.run
      end
      Thread.stop unless service.stopped?
      self
    end
    
  end
end
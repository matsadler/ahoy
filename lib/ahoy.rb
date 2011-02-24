base = File.expand_path("#{File.dirname(__FILE__)}/ahoy")
libs = %W{chat contact contact_list errors user}

libs.each do |lib|
  require "#{base}/#{lib}"
end

module Ahoy
  SERVICE_TYPE = "_presence._tcp"
  
  class << self
    attr_accessor :use_markdown
  end
  
  def self.more_coming?(reply)
    reply.flags.to_i & DNSSD::Flags::MoreComing > 0
  end
  
  def self.add?(reply)
    reply.flags.to_i & DNSSD::Flags::Add > 0
  end
end
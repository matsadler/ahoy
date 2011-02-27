base = File.expand_path("#{File.dirname(__FILE__)}/ahoy")
libs = %W{chat contact contact_list errors user}

libs.each do |lib|
  require "#{base}/#{lib}"
end

module Ahoy
  SERVICE_TYPE = "_presence._tcp"
  
  class << self
    attr_accessor :use_markdown # default for Chat#use_markdown
  end
  
  # :call-seq: Ahoy.more_coming?(reply) -> bool
  # 
  # Returns true if reply has the more coming flag set, false otherwise.
  # 
  def self.more_coming?(reply)
    reply.flags.to_i & DNSSD::Flags::MoreComing > 0
  end
  
  # :call-seq: Ahoy.add?(reply) -> bool
  # 
  # Returns true if reply has the add flag set, false otherwise.
  # 
  def self.add?(reply)
    reply.flags.to_i & DNSSD::Flags::Add > 0
  end
end
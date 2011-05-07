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
end
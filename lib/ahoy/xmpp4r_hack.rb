require 'rubygems'
require 'xmpp4r'

module Jabber
  class Connection
    def connect(host, port, local_host=nil, local_port=nil)
      @host = host
      @port = port
      # Reset is_tls?, so that it works when reconnecting
      @tls = false
      
      Jabber::debuglog("CONNECTING:\n#{@host}:#{@port}, local #{local_host}:#{local_port}")
      @socket = TCPSocket.new(@host, @port, local_host, local_port)
      
      # We want to use the old and deprecated SSL protocol (usually on port 5223)
      if @use_ssl
        ssl = OpenSSL::SSL::SSLSocket.new(@socket)
        ssl.connect # start SSL session
        ssl.sync_close = true
        Jabber::debuglog("SSL connection established.")
        @socket = ssl
      end
      
      start
      
      accept_features
      
      @keepaliveThread = Thread.new do
        Thread.current.abort_on_exception = true
        keepalive_loop
      end
    end
  end
  
  class Client
    def connect(host, port, local_host=nil, local_port=nil)
      super
      self
    end
  end
end
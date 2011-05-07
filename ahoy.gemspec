Gem::Specification.new do |s|
  s.name = "ahoy"
  s.version = "0.1.0"
  s.summary = "Bonjour Chat for Ruby"
  s.description = "Serverless Messaging using DNSDS/mDNS, XMPP, and Ruby"
  s.files = Dir["lib/**/*.rb"] << "readme.rdoc"
  s.require_path = "lib"
  s.has_rdoc = false
  s.rdoc_options << "--inline-source" << "--charset=UTF-8"
  s.author = "Mat Sadler"
  s.email = "mat@sourcetagsandcodes.com"
  s.homepage = "http://github.com/matsadler/ahoy"
  s.add_dependency("dnssd", ["~> 2.0"])
  s.add_dependency("xmpp4r", ["= 0.5"])
end
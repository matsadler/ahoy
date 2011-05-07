require 'thread'
require 'weakref'

module Ahoy
  
  # Ahoy::ContactList is a self-populating collection of Contacts, and provides
  # methods to retrieve and iterate over its contents.
  # 
  class ContactList
    include Enumerable
    
    attr_reader :list, :weak_list, :lock, :user_name
    private :list, :weak_list, :lock
    
    # :call-seq: ContactList.new(user_name=nil) -> contact_list
    # 
    # Create a new Ahoy::ContactList. Provide a username as the argument to
    # avoid adding our user to the list.
    # 
    def initialize(user_name=nil)
      @user_name = user_name
      @list = []
      @weak_list = []
      @lock = Mutex.new
      
      start_browse
    end
    
    # :call-seq: contact_list.each {|contact| block } -> contact_list
    # 
    # Calls block once for each contact in the contact list.
    # 
    def each(&block)
      lock.synchronize {list.each(&block)}
      self
    end
    
    # :call-seq: contact_list[name] -> contact or nil
    # 
    # Returns the first contact who's fullname or name matches name.
    # 
    # The case equality operator (===) is used in the comparison, so strings or
    # regexps can be used as the argument.
    # 
    def [](name)
      find {|c| name === c.fullname || name === c.name}
    end
    alias find_by_name []
    
    # :call-seq: contact_list.find_by_ip(string) -> contact or nil
    # 
    # Returns the first contact with the ip address matching string.
    # 
    def find_by_ip(ip)
      find {|contact| contact.ip_addresses.include?(ip)}
    end
    
    private
    def start_browse
      DNSSD.browse(Ahoy::SERVICE_TYPE) do |browsed|
        if browsed.flags.add? && browsed.name != user_name
          existing = self[browsed.fullname]
          contact = existing || find_in_weak_list(browsed.fullname) ||
            Ahoy::Contact.new(browsed.name, browsed.domain)
          contact.online = true
          contact.add_interface(browsed.interface)
          lock.synchronize {list.push(contact)} unless existing
        else
          remove(browsed.fullname)
        end
      end
    end
    
    def remove(fullname)
      lock.synchronize do
        contact = list.find {|c| c.fullname == fullname}
        if contact
          list.delete(contact)
          contact.online = false
          weak_list.push(WeakRef.new(contact))
          contact
        end
      end
    end
    
    def find_in_weak_list(fullname)
      Thread.exclusive do
        begin
          GC.disable
          weak_list.reject! {|ref| !ref.weakref_alive?}
          refrence = weak_list.find {|ref| fullname == ref.fullname}
          refrence.__getobj__ if refrence
        ensure
          GC.enable
        end
      end
    end
    
  end
end
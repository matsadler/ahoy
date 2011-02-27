require 'thread'
require 'weakref'

module Ahoy
  class ContactList
    include Enumerable
    
    attr_reader :list, :weak_list, :lock, :user
    private :list, :weak_list, :lock
    
    def initialize(user)
      @user = user
      @list = []
      @weak_list = []
      @lock = Mutex.new
      
      start_browse
    end
    
    def each(&block)
      lock.synchronize do
        list.each(&block)
      end
    end
    
    def [](name)
      find {|c| name === c.fullname || name === c.name}||find_in_weak_list(name)
    end
    
    private
    def start_browse
      DNSSD.browse(Ahoy::SERVICE_TYPE) do |browsed|
        if Ahoy::add?(browsed) && browsed.name != user.name
          contact = self[browsed.fullname] || Ahoy::Contact.new(browsed.name, browsed.domain)
          contact.online = true
          contact.add_interface(browsed.interface)
          lock.synchronize {list.push(contact)}
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
    
    def find_in_weak_list(name)
      name = name.fullname if name.respond_to?(:fullname)
      contact = nil
      Thread.exclusive do
        GC.disable
        weak_list.reject! {|ref| !ref.weakref_alive?}
        refrence = weak_list.find {|ref| name===ref.fullname || name===ref.name}
        contact = refrence.__getobj__ if refrence
        GC.enable
      end
      contact
    end
    
  end
end
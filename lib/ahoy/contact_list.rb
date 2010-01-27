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
    
    private
    def start_browse
      DNSSD.browse(Ahoy::SERVICE_TYPE) do |browsed|
        # next if Ahoy::more_coming?(browsed)
        if Ahoy::add?(browsed) && browsed.name != user.name
          add(Ahoy::Contact.new(browsed.name, browsed.domain))
        elsif Ahoy::add?(browsed)
          user.contact = Ahoy::Contact.new(browsed.name, browsed.domain)
        else
          remove(browsed.fullname)
        end
      end
    end
    
    def add(contact)
      lock.synchronize do
        unless list.find {|in_list| contact == in_list}
          contact ||= find_in_weak_list(contact)
          contact.online = true
          list.push(contact)
        end
      end
    end
    
    def remove(fullname)
      fullname = fullname.fullname if fullname.respond_to?(:fullname)
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
    
    def find_in_weak_list(contact)
      existing_contact = nil
      Thread.exclusive do
        GC.disable
        weak_list.select! {|ref| ref.weakref_alive?}
        contact_ref = weak_list.find {|ref| contact == ref}
        existing_contact = contact_ref.__getobj__
        GC.enable
      end
      existing_contact
    end
    
  end
end
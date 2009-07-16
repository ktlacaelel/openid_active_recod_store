require 'md5'

module OpenidStoreActiveRecord

  def self.included(klass)
    klass.extend ClassMethods
    klass.send(:include, InstanceMethods)
  end

  module ClassMethods
  end

  module InstanceMethods

    def targetize(server_url)
      MD5.hexdigest(server_url)
    end

  end

end

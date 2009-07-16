# OpenidStoreActiveRecord
module OpenidStoreActiveRecord

  def self.included(klass)
    klass.extend ClassMethods
    klass.send(:include, InstanceMethods)
  end

  module ClassMethods
  end

  module InstanceMethods
  end

end

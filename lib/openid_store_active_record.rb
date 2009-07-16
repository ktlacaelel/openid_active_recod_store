require 'md5'

module OpenidStoreActiveRecord

  def self.included(klass)
    klass.extend ClassMethods
    klass.send(:include, InstanceMethods)
  end

  module ClassMethods
  end

  module InstanceMethods

    protected

    def targetize(server_url)
      MD5.hexdigest(server_url)
    end

    def build_association(open_id_association)
      OpenID::Association.new(
        open_id_association.handle,
        open_id_association.secret,
        open_id_association.issued,
        open_id_association.lifetime,
        open_id_association.assoc_type
      )
    end

  end

end

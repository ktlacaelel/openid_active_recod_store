require 'openid/util'
require 'openid/store/interface'
require 'openid/association'

module OpenID
  module Store
    class ActiveRecord < Interface

      include OpenidStoreActiveRecord

      def initialize
        # XXX XXX XXX REMOVE XXX XXX XXX
        @nonces = {}
        # XXX XXX XXX REMOVE XXX XXX XXX
      end

      # Put a Association object into storage.
      # When implementing a store, don't assume that there are any limitations
      # on the character set of the server_url.  In particular, expect to see
      # unescaped non-url-safe characters in the server_url field.
      def store_association(server_url, association)
        oa = OpenidAssociation.new
        oa.server_url = server_url
        oa.target = targetize(server_url)
        oa.handle = association.handle
        oa.secret = association.secret
        oa.issued = association.issued
        oa.lifetime = association.lifetime
        oa.assoc_type = association.assoc_type
        oa.save
      end

      # Returns a Association object from storage that matches
      # the server_url.  Returns nil if no such association is found or if
      # the one matching association is expired. (Is allowed to GC expired
      # associations when found.)
      def get_association(server_url, handle=nil)
        oas = OpenidAssociation.find_all_by_target targetize(server_url)
        return nil if oas.empty?
        unless handle.nil?
          return nil unless oas.collect(&:handle).include? handle
          return build_association(oas.find { |oa| oa.handle == handle })
        end
        oas.sort_by(&:issued).collect { |oa| build_association(oa) }.last
      end

      # If there is a matching association, remove it from the store and
      # return true, otherwise return false.
      def remove_association(server_url, handle)
        oas = OpenidAssociation.find_all_by_target targetize(server_url)
        return false unless oas.collect(&:handle).include? handle
        oas.find_all { |oa| oa.handle == handle }.each(&:delete).size > 0
      end

      # Return true if the nonce has not been used before, and store it
      # for a while to make sure someone doesn't try to use the same value
      # again.  Return false if the nonce has already been used or if the
      # timestamp is not current.
      # You can use OpenID::Store::Nonce::SKEW for your timestamp window.
      # server_url: URL of the server from which the nonce originated
      # timestamp: time the nonce was created in seconds since unix epoch
      # salt: A random string that makes two nonces issued by a server in
      #       the same second unique
      def use_nonce(server_url, timestamp, salt)
        return false if (timestamp - Time.now.to_i).abs > Nonce.skew
        nonce = [server_url, timestamp, salt].join('')
        return false if @nonces[nonce]
        @nonces[nonce] = timestamp
        return true
      end

      # Remove expired nonces and associations from the store
      # Not called during normal library operation, this method is for store
      # admins to keep their storage from filling up with expired data
      def cleanup
        count = 0
        @associations.each{|server_url, assocs|
          assocs.each{|handle, assoc|
            if assoc.expires_in == 0
              assocs.delete(handle)
              count += 1
            end
          }
        }
        return count
      end

      # Remove expired associations from the store
      # Not called during normal library operation, this method is for store
      # admins to keep their storage from filling up with expired data
      def cleanup_associations
        count = 0
        oas = OpenidAssociation.all.each do |oa|
          if build_association(oa).expires_in == 0
            oa.delete
            count += 1
          end
        end
        return count
      end

      # Remove expired nonces from the store
      # Discards any nonce that is old enough that it wouldn't pass use_nonce
      # Not called during normal library operation, this method is for store
      # admins to keep their storage from filling up with expired data
      def cleanup_nonces
        count = 0
        now = Time.now.to_i
        @nonces.each{|nonce, timestamp|
          if (timestamp - now).abs > Nonce.skew
            @nonces.delete(nonce)
            count += 1
          end
        }
        return count
      end

    end
  end
end

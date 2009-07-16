require 'test_helper'

class OpenidStoreActiveRecordTest < ActiveSupport::TestCase

  # ============================================================================
  # TESTING SCENARIO
  # ============================================================================

  setup :prepare_scenario, :clean_tables
  teardown :destroy_scenario

  def prepare_scenario
    @store = OpenID::Store::ActiveRecord.new
    @@allowed_nonce = '0123456789abcdefghijklmnopqrst' +
      'uvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    @@allowed_handle = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ' +
      'RSTUVWXYZ!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'
  end

  def clean_tables
  # OpenidAssociation.all.each do |ao|
  #   ao.destroy
  # end
  end

  def destroy_scenario
    @@allowed_handle = @@allowed_nonce = @store = nil
  end

  # ============================================================================
  # METHODS BROUGHT FROM THE ORIGINAL 'ruby-openid' test suite
  # ============================================================================

  def _gen_secret(n, chars=nil)
    OpenID::CryptUtil.random_string(n, chars)
  end

  def _gen_handle(n)
    OpenID::CryptUtil.random_string(n, @@allowed_handle)
  end

  def _gen_assoc(issued, lifetime=600)
    secret = _gen_secret(20)
    handle = _gen_handle(128)
    OpenID::Association.new(handle, secret, Time.now + issued, lifetime,
                            'HMAC-SHA1')
  end

  def _check_retrieve(url, handle=nil, expected=nil)
    ret_assoc = @store.get_association(url, handle)

    if expected.nil?
      assert_nil(ret_assoc)
    else
      assert_equal(expected, ret_assoc)
      assert_equal(expected.handle, ret_assoc.handle)
      assert_equal(expected.secret, ret_assoc.secret)
    end
  end

  def _check_remove(url, handle, expected)
    present = @store.remove_association(url, handle)
    assert_equal(expected, present)
  end

  def test_store
    server_url = "http://www.myopenid.com/openid"
    assoc = _gen_assoc(issued=0)

    # Make sure that a missing association returns no result
    _check_retrieve(server_url)

    # Check that after storage, getting returns the same result
    @store.store_association(server_url, assoc)
    _check_retrieve(server_url, nil, assoc)

    # more than once
    _check_retrieve(server_url, nil, assoc)

    # Storing more than once has no ill effect
    @store.store_association(server_url, assoc)
    _check_retrieve(server_url, nil, assoc)

    # Removing an association that does not exist returns not present
    _check_remove(server_url, assoc.handle + 'x', false)

    # Removing an association that does not exist returns not present
    _check_remove(server_url + 'x', assoc.handle, false)

    # Removing an association that is present returns present
    _check_remove(server_url, assoc.handle, true)

    # but not present on subsequent calls
    _check_remove(server_url, assoc.handle, false)

    # Put assoc back in the store
    @store.store_association(server_url, assoc)

    # More recent and expires after assoc
    assoc2 = _gen_assoc(issued=1)
    @store.store_association(server_url, assoc2)

    # After storing an association with a different handle, but the
    # same server_url, the handle with the later expiration is returned.
    _check_retrieve(server_url, nil, assoc2)

    # We can still retrieve the older association
    _check_retrieve(server_url, assoc.handle, assoc)

    # Plus we can retrieve the association with the later expiration
    # explicitly
    _check_retrieve(server_url, assoc2.handle, assoc2)

    # More recent, and expires earlier than assoc2 or assoc. Make sure
    # that we're picking the one with the latest issued date and not
    # taking into account the expiration.
    assoc3 = _gen_assoc(issued=2, lifetime=100)
    @store.store_association(server_url, assoc3)

    _check_retrieve(server_url, nil, assoc3)
    _check_retrieve(server_url, assoc.handle, assoc)
    _check_retrieve(server_url, assoc2.handle, assoc2)
    _check_retrieve(server_url, assoc3.handle, assoc3)

    _check_remove(server_url, assoc2.handle, true)

    _check_retrieve(server_url, nil, assoc3)
    _check_retrieve(server_url, assoc.handle, assoc)
    _check_retrieve(server_url, assoc2.handle, nil)
    _check_retrieve(server_url, assoc3.handle, assoc3)

    _check_remove(server_url, assoc2.handle, false)
    _check_remove(server_url, assoc3.handle, true)

    _check_retrieve(server_url, nil, assoc)
    _check_retrieve(server_url, assoc.handle, assoc)
    _check_retrieve(server_url, assoc2.handle, nil)
    _check_retrieve(server_url, assoc3.handle, nil)

    _check_remove(server_url, assoc2.handle, false)
    _check_remove(server_url, assoc.handle, true)
    _check_remove(server_url, assoc3.handle, false)

    _check_retrieve(server_url, nil, nil)
    _check_retrieve(server_url, assoc.handle, nil)
    _check_retrieve(server_url, assoc2.handle, nil)
    _check_retrieve(server_url, assoc3.handle, nil)

    _check_remove(server_url, assoc2.handle, false)
    _check_remove(server_url, assoc.handle, false)
    _check_remove(server_url, assoc3.handle, false)

    assocValid1 = _gen_assoc(-3600, 7200)
    assocValid2 = _gen_assoc(-5)
    assocExpired1 = _gen_assoc(-7200, 3600)
    assocExpired2 = _gen_assoc(-7200, 3600)

    @store.cleanup_associations
    @store.store_association(server_url + '1', assocValid1)
    @store.store_association(server_url + '1', assocExpired1)
    @store.store_association(server_url + '2', assocExpired2)
    @store.store_association(server_url + '3', assocValid2)

    cleaned = @store.cleanup_associations()
    assert_equal(2, cleaned, "cleaned up associations")
  end

end

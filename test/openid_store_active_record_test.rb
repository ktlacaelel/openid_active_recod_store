require 'test_helper'

class OpenidStoreActiveRecordTest < ActiveSupport::TestCase

  setup :prepare_scenario
  teardown :destroy_scenario

  def prepare_scenario
    @store = OpenID::Store::ActiveRecord.new
  end

  def destroy_scenario
    @store = nil
  end

end

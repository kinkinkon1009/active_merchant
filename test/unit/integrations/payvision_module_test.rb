require 'test_helper'

class PayvisionModuleTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def test_notification_method
    assert_instance_of Payvision::Notification, Payvision.notification('name=cody')
  end
end

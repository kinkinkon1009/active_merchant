require 'test_helper'

class PayvisionNotificationTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def setup
    @payvision = Payvision::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @payvision.complete?
    assert_equal "", @payvision.status
    assert_equal "", @payvision.transaction_id
    assert_equal "", @payvision.item_id
    assert_equal "", @payvision.gross
    assert_equal "", @payvision.currency
    assert_equal "", @payvision.received_at
    assert @payvision.test?
  end

  def test_compositions
    assert_equal Money.new(3166, 'USD'), @payvision.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement

  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @payvision.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    ""
  end
end

require 'test_helper'

class PayvisionTest < Test::Unit::TestCase
  def setup
    @gateway = PayvisionGateway.new(
                 :memberId => '1002359',
                 :memberGuid => '399FE286-00D2-485C-9925-7B7D48A35D32'
               )

    @credit_card = CreditCard.new(
        number: '4907639999990022',
        first_name: 'Test',
        last_name: 'Taro',
        month: 12,
        year: 2016
    )

    # TODO Ayumue RecurringCardを作成予定
    @recurring_card ={
        cardId: '4974183',
        cardGuid: '6cb3dd55-c56a-4bf2-98d0-6c5165bea51b'
    }


    # TODO Ayumue RecurringCardを作成予定
    @authorization = {
        transactionId: '18937823',
        transactionGuid: 'c3f17db4-4152-4350-9de1-9c5989b5a381',
        currencyId: '840',
        trackingMemberCode: 'test5'
    }

    @amount = 600

    @options = {
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end


  def test_successful_regsitercard
    @gateway.expects(:ssl_post).returns(successful_registercard_response)

    assert response = @gateway.registercard(@credit_card, @options)
    assert_instance_of Response, response
    assert_success response
    # TODO Ayumu 2014.3.15 logの出力方式を考える必要あり
    #puts nil
    #puts "########### test_successful_regsitercard response ###############"
    #puts response.inspect

    # Replace with authorization number from the successful response
    #assert_equal '', response.authorization
    assert response.test?
  end

  def test_successful_authorize
    @gateway.expects(:ssl_post).returns(successful_authorize_response)

    assert response = @gateway.authorize(@amount, @recurring_card, @options)
    assert_instance_of Response, response
    assert_success response

    # Replace with authorization number from the successful response
    #assert_equal '', response.authorization
    assert response.test?
  end

  def test_successful_capture
    @gateway.expects(:ssl_post).returns(successful_capture_response)

    assert response = @gateway.capture(@amount, @authorization, @options)
    assert_instance_of Response, response
    assert_success response

    # Replace with authorization number from the successful response
    #assert_equal '', response.authorization
    assert response.test?
  end

  def test_successful_void
    @gateway.expects(:ssl_post).returns(successful_capture_response)

    assert response = @gateway.void(@authorization, @options)
    assert_instance_of Response, response
    assert_success response

    # Replace with authorization number from the successful response
    #assert_equal '', response.authorization
    assert response.test?
  end

  # TODO Ayumu 備忘めもの為に残している
  #def test_successful_purchase
  #  @gateway.expects(:ssl_post).returns(successful_purchase_response)
  #
  #  assert response = @gateway.purchase(@amount, @credit_card, @options)
  #  assert_instance_of Response, response
  #  assert_success response
  #
  #  # Replace with authorization number from the successful response
  #  assert_equal '', response.authorization
  #  assert response.test?
  #end

  #def test_unsuccessful_request
  #  @gateway.expects(:ssl_post).returns(failed_purchase_response)
  #
  #  assert response = @gateway.purchase(@amount, @credit_card, @options)
  #  assert_failure response
  #  assert response.test?
  #end

  private

  def successful_registercard_response
    <<-RESPONSE
      <?xml version="1.0" encoding="utf-8"?>
      <RegisterCardResult xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://payvision.com/gateway/">
        <Result>0</Result>
        <Message>The operation was successfully processed.</Message>
        <CardId>4974075</CardId>
        <CardGuid>0a20c523-d24a-4d45-95c9-65cc7fc0412c</CardGuid>
      </RegisterCardResult>
    RESPONSE
  end

  def successful_capture_response
    <<-RESPONSE
      <?xml version=\"1.0\" encoding=\"utf-8\"?>
      <TransactionResult xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://payvision.com/gateway/\">
        <Result>0</Result>
        <Message>The operation was successfully processed.</Message>
        <TrackingMemberCode>test4</TrackingMemberCode>
        <TransactionId>19100673</TransactionId>
        <TransactionGuid>c1baba87-eda0-4795-9e4e-2b1496608640</TransactionGuid>
        <TransactionDateTime>2014-03-15T16:32:25.4172916Z</TransactionDateTime>
        <Cdc>
          <CdcEntry>
            <Name>BankInformation</Name>
            <Items>
              <CdcEntryItem>
                <Key>BankCode</Key>
                <Value>00</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>BankMessage</Key>
                <Value>Approved</Value>
              </CdcEntryItem>
            </Items>
          </CdcEntry>
          <CdcEntry>
            <Name>CardInformation</Name>
            <Items>
              <CdcEntryItem>
                <Key>CardId</Key>
                <Value>4974075</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>CardGuid</Key>
                <Value>0a20c523-d24a-4d45-95c9-65cc7fc0412c</Value>
              </CdcEntryItem>
            </Items>
          </CdcEntry>
        </Cdc>
      </TransactionResult>
    RESPONSE
  end

  # TODO Ayumu 取得データでエラーがいくつかある
  def successful_authorize_response
    <<-RESPONSE
      <?xml version=\"1.0\" encoding=\"utf-8\"?>
      <TransactionResult xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://payvision.com/gateway/\">
        <Result>0</Result>
        <Message>The operation was successfully processed.</Message>
        <TrackingMemberCode>test2</TrackingMemberCode>
        <TransactionId>19093561</TransactionId>
        <TransactionGuid>b18fac4e-a673-425d-b15c-34e76c66d6bb</TransactionGuid>
        <TransactionDateTime>2014-03-15T08:27:35.1809925Z</TransactionDateTime>
        <Cdc>
          <CdcEntry>
            <Name>BankInformation</Name>
            <Items>
              <CdcEntryItem>
                <Key>BankCode</Key>
                <Value>00</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>BankMessage</Key>
                <Value>Approved</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>BankApprovalCode</Key>
                <Value>530247</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>Error</Key>
                <Value>Cvv must be sent for E-Commerce transactions</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>Error</Key>
                <Value>DynamicDescriptor is sent for a merchant account that does not support it</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>Warning</Key>
                <Value>avsAddress and/or avsZip empty</Value>
              </CdcEntryItem>
            </Items>
          </CdcEntry>
          <CdcEntry>
            <Name>CardInformation</Name>
            <Items>
              <CdcEntryItem>
                <Key>CardId</Key>
                <Value>4974075</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>CardGuid</Key>
                <Value>0a20c523-d24a-4d45-95c9-65cc7fc0412c</Value>
              </CdcEntryItem>
            </Items>
          </CdcEntry>
        </Cdc>
      </TransactionResult>
    RESPONSE
  end

  # Place raw successful response from gateway here
  def successful_void_response
    <<-RESPONSE
      <?xml version=\"1.0\" encoding=\"utf-8\"?>
      <TransactionResult xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://payvision.com/gateway/\">
        <Result>0</Result>
        <Message>The operation was successfully processed.</Message>
        <TrackingMemberCode>test8</TrackingMemberCode>
        <TransactionId>19102917</TransactionId>
        <TransactionGuid>d6bc65db-3417-4cd0-ad81-ffc5b80585a2</TransactionGuid>
        <TransactionDateTime>2014-03-16T05:52:49.5479394Z</TransactionDateTime>
        <Cdc>
          <CdcEntry>
            <Name>BankInformation</Name>
            <Items>
              <CdcEntryItem>
                <Key>BankCode</Key>
                <Value>00</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>BankMessage</Key>
                <Value>Approved</Value>
              </CdcEntryItem>
            </Items>
          </CdcEntry>
          <CdcEntry>
            <Name>CardInformation</Name>
            <Items>
              <CdcEntryItem>
                <Key>CardId</Key>
                <Value>4974183</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>CardGuid</Key>
                <Value>6cb3dd55-c56a-4bf2-98d0-6c5165bea51b</Value>
              </CdcEntryItem>
            </Items>
          </CdcEntry>
        </Cdc>
      </TransactionResult>
    RESPONSE
  end

  # Place raw failed response from gateway here
  def failed_purchase_response
  end

  def failed_void_response
    <<-RESPONSE
      <?xml version=\"1.0\" encoding=\"utf-8\"?>
        <TransactionResult xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://payvision.com/gateway/\">
          <Result>1000</Result>
          <Message>Invalid arguments. One or more arguments have invalid values. Please review the parameters sent</Message>
          <TrackingMemberCode>test4</TrackingMemberCode>
          <TransactionId>0</TransactionId>
          <TransactionGuid>00000000-0000-0000-0000-000000000000</TransactionGuid>
          <TransactionDateTime>2014-03-16T05:36:24.2878998Z</TransactionDateTime>
          <Cdc>
            <CdcEntry>
              <Name>ErrorInformation</Name>
              <Items>
                <CdcEntryItem>
                  <Key>ErrorCode</Key>
                  <Value>1000001</Value>
                </CdcEntryItem>
                <CdcEntryItem>
                  <Key>ErrorMessage</Key>
                  <Value>The Tracking Member Code sent is invalid. It must be unique at least during 24 hours</Value>
                </CdcEntryItem>
              </Items>
            </CdcEntry>
          </Cdc>
        </T\ansactionResult>
    RESPONSE
  end
end

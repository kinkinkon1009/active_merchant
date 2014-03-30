require 'test_helper'

class PayvisionTest < Test::Unit::TestCase

  # ------------------------------------------------
  #                                       Definition
  #                                       ----------
  def setup
    options = {:memberId => '1002359',:memberGuid => '399FE286-00D2-485C-9925-7B7D48A35D32'}

    @gateway = PayvisionGateway.new(options)

    @credit_card = CreditCard.new(
        # テスト用（成功）
        number: '4907639999990022',
        first_name: 'Test',
        last_name: 'Taro',
        month: 12,
        year: 2016
    )

    @recurring_card ={
        cardId: '4974183',
        cardGuid: '6cb3dd55-c56a-4bf2-98d0-6c5165bea51b'
    }

    @authorization = {
        transactionId: '19223127',
        transactionGuid: '93c837f6-ce73-45c2-b8eb-268f6eb412b6',
        currencyId: '840',
        trackingMemberCode: Time.now
    }

    @purchase = {
        countryId: '840',
        currencyId: '840',
        trackingMemberCode: Time.now,
        merchantAccountType: '4',
        dynamicDescriptor: 'Baboo|+85281760914',
        avsAddress: '',
        avsZip: ''
    }

    @amount = 600

    @options = {
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end


  # ------------------------------------------------
  #                                             Test
  #                                             ----
  def test_successful_regsitercard
    @gateway.expects(:ssl_post).returns(successful_registercard_response)

    assert response = @gateway.registercard(@credit_card, @options)
    puts "register_card --------------------"
    puts response.inspect
    assert_instance_of Response, response
    assert_success response

    assert response.test?
  end

  def test_successful_authorize
    @gateway.expects(:ssl_post).returns(successful_authorize_response)
    assert response = @gateway.authorize(@amount, @recurring_card, @purchase, @options)
    puts "authorize --------------------"
    puts response.inspect
    assert_instance_of Response, response
    assert_success response

    assert response.test?
  end

  def test_successful_capture
    @gateway.expects(:ssl_post).returns(successful_capture_response)

    assert response = @gateway.capture(@amount, @authorization, @options)
    assert_instance_of Response, response
    assert_success response

    assert response.test?
  end

  def test_successful_void
    @gateway.expects(:ssl_post).returns(successful_capture_response)

    assert response = @gateway.void(@authorization, @options)
    assert_instance_of Response, response
    assert_success response

    assert response.test?
  end

  def test_successful_payment
    @gateway.expects(:ssl_post).returns(successful_payment_response)

    assert response = @gateway.payment(@amount, @recurring_card, @purchase, @options)
    assert_instance_of Response, response
    assert_success response

    # レスポンスを確認
    #puts response.inspect

    assert response.test?
  end

  def test_successful_credit
    @gateway.expects(:ssl_post).returns(successful_credit_response)

    assert response = @gateway.credit(@amount, @recurring_card, @purchase, @options)
    assert_instance_of Response, response
    assert_success response

    # レスポンスを確認
    puts response.inspect

    assert response.test?
  end

  # TODO アカウントの制限で実行できない
  #def test_successful_fundtransfer
  #  #@gateway.expects(:ssl_post).returns(successful_fundtransfer_response)
  #
  #  assert response = @gateway.fundtransfer(@amount, @recurring_card, @purchase, @options)
  #  assert_instance_of Response, response
  #  assert_success response
  #
  #  # レスポンスを確認
  #  #puts response.inspect
  #
  #  assert response.test?
  #end

  def test_successful_refund
    @gateway.expects(:ssl_post).returns(successful_refund_response)

    assert response = @gateway.refund(@amount, @authorization, @options)
    assert_instance_of Response, response
    assert_success response

    # レスポンスを確認
    #puts response.inspect

    assert response.test?
  end

  private

  # ------------------------------------------------
  #                                             Mock
  #                                             ----
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

  def successful_payment_response
    <<-RESPONSE
      <?xml version=\"1.0\" encoding=\"utf-8\"?>
      <TransactionResult xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://payvision.com/gateway/\">
        <Result>0</Result>
        <Message>The operation was successfully processed.</Message>
        <TrackingMemberCode>2014-03-30 15:14:00 +0900</TrackingMemberCode>
        <TransactionId>19223127</TransactionId>
        <TransactionGuid>93c837f6-ce73-45c2-b8eb-268f6eb412b6</TransactionGuid>
        <TransactionDateTime>2014-03-30T06:14:00.0636451Z</TransactionDateTime>
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
                <Value>334102</Value>
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

  def successful_refund_response
    <<-RESPONSE
      <?xml version=\"1.0\" encoding=\"utf-8\"?>
      <TransactionResult xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://payvision.com/gateway/\">
        <Result>0</Result>
        <Message>The operation was successfully processed.</Message>
        <TrackingMemberCode>2014-03-30 15:I18n.t(''):45 +0900</TrackingMemberCode>
        <TransactionId>19223135</TransactionId>
        <TransactionGuid>3b6339a7-16f1-4931-8c05-5962d8fc3765</TransactionGuid>
        <TransactionDateTime>2014-03-30T06:I18n.t(''):44.3905753Z</TransactionDateTime>
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
                <Value>092647</Value>
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

  def successful_credit_response
    <<-RESPONSE
      <?xml version=\"1.0\" encoding=\"utf-8\"?>
      <TransactionResult xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://payvision.com/gateway/\">
        <Result>0</Result>
        <Message>The operation was successfully processed.</Message>
        <TrackingMemberCode>2014-03-30 15:39:10 +0900</TrackingMemberCode>
        <TransactionId>19223151</TransactionId>
        <TransactionGuid>08c267bf-bd85-4638-818f-cacf0e3446dd</TransactionGuid>
        <TransactionDateTime>2014-03-30T06:39:10.1575126Z</TransactionDateTime>
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
                <Value>666507</Value>
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

  # Template
  ## Place raw failed response from gateway here
  #def successful_payment_response
  #  <<-RESPONSE
  #  RESPONSE
  #end
  #
  ## Place raw failed response from gateway here
  #def failed_purchase_response
  #  <<-RESPONSE
  #  RESPONSE
  #end

  def failed_fundtransfer_response
    <<-RESPONSE
      <?xml version=\"1.0\" encoding=\"utf-8\"?>
      <TransactionResult xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://payvision.com/gateway/\">
        <Result>1000</Result>
        <Message>Invalid arguments. One or more arguments have invalid values. Please review the parameters sent</Message>
        <TrackingMemberCode>2014-03-30 15:43:21 +0900</TrackingMemberCode>
        <TransactionId>0</TransactionId>
        <TransactionGuid>00000000-0000-0000-0000-000000000000</TransactionGuid>
        <TransactionDateTime>2014-03-30T06:43:20.4479111Z</TransactionDateTime>
        <Cdc>
          <CdcEntry>
            <Name>ErrorInformation</Name>
            <Items>
              <CdcEntryItem>
                <Key>ErrorCode</Key>
                <Value>1000092</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>ErrorMessage</Key>
                <Value>The merchant account does not allow Card Fund Transfer operations.</Value>
              </CdcEntryItem>
            </Items>
          </CdcEntry>
        </Cdc>
      </TransactionResult>
    RESPONSE
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

  def failed_refund_response
    <<-RESPONSE
      <?xml version=\"1.0\" encoding=\"utf-8\"?>
      <TransactionResult xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://payvision.com/gateway/\">
        <Result>1000</Result>
        <Message>Invalid arguments. One or more arguments have invalid values. Please review the parameters sent</Message>
        <TrackingMemberCode>2014-03-30 15:14:02 +0900</TrackingMemberCode>
        <TransactionId>0</TransactionId>
        <TransactionGuid>00000000-0000-0000-0000-000000000000</TransactionGuid>
        <TransactionDateTime>2014-03-30T06:14:02.0472219Z</TransactionDateTime>
        <Cdc>
          <CdcEntry>
            <Name>ErrorInformation</Name>
            <Items>
              <CdcEntryItem>
                <Key>ErrorCode</Key>
                <Value>1000021</Value>
              </CdcEntryItem>
              <CdcEntryItem>
                <Key>ErrorMessage</Key>
                <Value>The required operation is not allowed. Please review the parameters and try to send it again.</Value>
              </CdcEntryItem>
            </Items>
          </CdcEntry>
        </Cdc>
      </TransactionResult>
    RESPONSE
  end

end

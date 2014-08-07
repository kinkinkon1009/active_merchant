begin
  require 'nokogiri'
rescue LoadError
  # Falls back to an SSL post to Payvision
end

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PayvisionGateway < Gateway
      self.test_url = 'https://testprocessor.payvisionservices.com/Gateway/'
      self.live_url = 'https://processor.payvisionservices.com/Gateway/'

      SUCCESS_TYPES = ["0"]

      URL_PREFIX_BASIC_ACTIONS = 'BasicOperations.asmx/'
      URL_PREFIX_RECURRING_ACTIONS = 'RecurringOperations.asmx/'

      ACTION_TYPES_TO_CAP ={
          "basic" => "BASIC_ACTIONS",
          "recurring" => "RECURRING_ACTIONS"
      }

      BASIC_ACTIONS = {
          "capture" => "Capture",
          "void" => "Void",
          "refund" => "Refund",
      }

      RECURRING_ACTIONS = {
          "registercard" => "RegisterCard",
          "authorize" => "Authorize",
          "payment" => "Payment",
          "credit" => "Credit", # 未実装
          "fundtransfer" => "CardFundTransfer" # 未実装
      }

      # TODO AYUMU 他のにも登録していく必要がある
      RESULT_TYPES = {
          "authorize" => "TransactionResult",
          "capture" => "TransactionResult",
          "void" => "TransactionResult",
          "refund" => "TransactionResult",
          "credit" => "TransactionResult",
          "fundtransfer" => "TransactionResult",
          "payment" => "TransactionResult",
          "registercard" => "RegisterCardResult"
      }

      def initialize(options = {})
        requires!(options, :memberId, :memberGuid)
        super
      end

      # ------------------------------------------------
      #                                  Recuring Action
      #                                  ---------------
      # カード登録
      #@param creditcard: ActiveMerchant::Billing::CreditCard
      #@params options: 特に利用していない
      def registercard(creditcard, options = {})
        post = {}
        add_registercard(post, creditcard)
        commit('registercard', post, 'recurring')
      end

      # 与信取得
      #@param recurringcard: ハッシュ必須項目 cardId, cardGuid
      #@param purchase: ハッシュ必須項目 countryId, currencyId, trackingMemberCode, merchantAccountType, dynamicDescriptor, avsAddress, avsZip
      #@param options
      def authorize(money, recurringcard, purchase, options = {})
        post = {}
        add_recurringcard(post, recurringcard)
        add_purchase(post, money, purchase)
        commit('authorize', post, 'recurring')
      end

      # 一括決済(authorize + capture と同様)
      def payment(money, recurringcard, purchase, options = {})
        post = {}
        add_recurringcard(post, recurringcard)
        add_purchase(post, money, purchase)
        commit('payment', post, 'recurring')
      end

      # 返金
      def credit(money, recurringcard, purchase, options = {})
        post = {}
        add_recurringcard(post, recurringcard)
        add_purchase(post, money, purchase)
        commit('credit', post, 'recurring')
      end

      # 送金
      def fundtransfer(money, recurringcard, purchase, options = {})
        post = {}
        add_recurringcard(post, recurringcard)
        add_purchase(post, money, purchase)
        commit('fundtransfer', post, 'recurring')
      end

      # ------------------------------------------------
      #                                     Basic Action
      #                                     ------------
      # 決済確定
      def capture(money, authorization, options = {})
        post = {}
        add_authorization(post, money, authorization)
        commit('capture', post, 'basic')
      end

      # 与信キャンセル
      def void(authorization, options = {})
        post = {}
        add_authorization(post, nil, authorization);
        commit('void', post, 'basic')
      end

      # 返金(capture、paymentと紐づく必要あり)
      def refund(money, authorization, options = {})
        post = {}
        add_authorization(post, money, authorization);
        commit('refund', post, 'basic')
      end


      private

      # カード情報をpostデータに登録
      #@param [post]
      #@param creditcard: ActiveMerchant::Billing::CreditCard
      def add_registercard(post, creditcard)
        post[:number] = creditcard.number
        post[:holder] = creditcard.name
        post[:expiryMonth] = creditcard.month
        post[:expiryYear] = creditcard.year
        post[:cardType] = creditcard.brand
      end

      # 登録カード情報をpostデータに登録
      def add_recurringcard(post, recurringcard)
        post[:cardId] = recurringcard[:cardId]
        post[:cardGuid] = recurringcard[:cardGuid]
      end

      # 与信取得のデータをpostデータに登録
      #@param [post]
      #@param money
      #@param purchase ハッシュ必須項目 countryId, currencyId, trackingMemberCode, merchantAccountType, dynamicDescriptor, avsAddress, avsZip
      #@return post
      def add_purchase(post, money, purchase)
        post[:amount] = money
        post[:countryId] = purchase[:countryId]
        post[:currencyId] = purchase[:currencyId]
        post[:trackingMemberCode] = purchase[:trackingMemberCode] # 1:EC 2:MOTO 4:RECURRING
        post[:merchantAccountType] = purchase[:merchantAccountType]
        post[:dynamicDescriptor] = purchase[:dynamicDescriptor]
        post[:avsAddress] = purchase[:avsAddress]
        post[:avsZip] = purchase[:avsZip]
      end

      # 取得している与信のデータをpostデータに登録
      #@param [post]
      #@param money
      #@param authorization ハッシュ必須項目 transactionId, transactionGuid, currencyId, trackingMemberCode
      #@return post
      def add_authorization(post, money, authorization = {})
        post[:transactionId] = authorization[:transactionId]
        post[:transactionGuid] = authorization[:transactionGuid]
        post[:currencyId] = authorization[:currencyId]
        post[:trackingMemberCode] = authorization[:trackingMemberCode]
        post[:amount] = money
      end

      def parse(data, action, action_type)
        # 取得データ
        #puts "[ data ]-------------------------"
        #puts data.inspect

        result = {}
        xml = Nokogiri::XML(data)
        xml.remove_namespaces!

        result_type = get_result_type(action)
        root = xml.xpath("//#{result_type}")

        root.children.each do |node|
          parse_element(result, node) if node.element?
        end

        return result
      end

      def commit(action, post, action_type)
        post[:memberId] = @options[:memberId]
        post[:memberGuid] = @options[:memberGuid]
        post[:action] = action

        # payvisionにpostする
        # INPUT データ
        #puts " --- start -----"
        #puts "[ post ] ---------------------------"
        #puts post.inspect

        success = false
        message = nil
        begin
          raw_response = ssl_post(action_url(action, action_type), post_data(post))
          response = parse(raw_response, action, action_type)
          success = SUCCESS_TYPES.include?(response[:result])
          message = message_from(response)
        rescue SocketError => e
          # インターネットに接続されていない場合：
          #puts "------ socket error -------------"
          response = {message: e.message}
            #puts e.message
        rescue ResponseError => e
          # パラメータが足りない場合も発生し得る：
          response = {message: "Server internal error. Sorry for inconvinience. Please contact us"}
          #puts "------ response error -------------"
          #puts e.inspect
        end

        # RESPONSE データ
        #puts "########## response ###########"
        #puts response.inspect
        Response.new(success, message, response,:test => test?)
      end

      def action_url(action, action_type)
        cap_action_type = get_cap_action(action_type)
        host_url = test? ? self.test_url : self.live_url
        prefix_url = eval("URL_PREFIX_#{cap_action_type}")

        #puts "[ url ] ---------------------------"
        #puts host_url + prefix_url + eval(cap_action_type)[action]
        return host_url + prefix_url + eval(cap_action_type)[action]
      end

      def get_result_type(action)
        RESULT_TYPES[action]
      end

      def get_cap_action(action_type)
        ACTION_TYPES_TO_CAP[action_type]
      end

      def parse_element(response, node)
        case node.name
          when 'Cdc'
            node.xpath(".//CdcEntry").each do |cdcentry|
              items = {}
              cdcentry.xpath("Items").children.each do |cdcitem|
                items[cdcitem.xpath("Key").text] = cdcitem.xpath("Value").text if cdcitem.element?
              end
              response[cdcentry.xpath("Name").text] = items
            end
          else
            node_name = node.name.underscore.to_sym
            response[node_name] = node.text
        end
      end

      def message_from(response)
        response[:message]
      end

      def post_data(parameters)
        parameters.collect { |key, value| "#{key}=#{ CGI.escape(value.to_s)}" }.join("&")
      end
    end
  end
end


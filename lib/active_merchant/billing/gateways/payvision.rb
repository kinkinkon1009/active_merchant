begin
  require 'nokogiri'
rescue LoadError
  # Falls back to an SSL post to Payvision
end

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PayvisionGateway < Gateway
      self.test_url  = 'https://testprocessor.payvisionservices.com/Gateway/'
      # TODO Ayumu 2014.3.15 まだ未定
      self.live_url = ''

      SUCCESS_TYPES = ["0"]

      URL_PREFIX_BASIC_ACTIONS = 'BasicOperations.asmx/'
      URL_PREFIX_RECURRING_ACTIONS = 'RecurringOperations.asmx/'

      ACTION_TYPES_TO_CAP ={
          "basic" => "BASIC_ACTIONS",
          "recurring" => "RECURRING_ACTIONS"
      }

      BASIC_ACTIONS = {
          "capture" => "Capture",
          "void" => "Void"
      }

      RECURRING_ACTIONS = {
          "registercard" => "RegisterCard",
          "authorize" => "Authorize",
          "credit" => "Credit",
          "fundtransfer" => "CardFundTransfer"
      }

      # TODO AYUMU 他のにも登録していく必要がある
      RESULT_TYPES = {
          "authorize" => "TransactionResult",
          "capture" => "TransactionResult",
          "void" => "TransactionResult",
          "registercard" => "RegisterCardResult"
      }


      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['US']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :american_express, :discover]

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.example.net/'

      # The name of the gateway
      self.display_name = 'New Gateway'

      def initialize(options = {})
        requires!(options, :memberId, :memberGuid)
        super
      end

      def authorize(money, recurringcard, options = {})
        post = {}
        add_recurringcard(post, recurringcard, money)
        commit('authorize', post, 'recurring')
      end

      def registercard(creditcard, options = {})
        post = {}
        add_registercard(post, creditcard)
        commit('registercard', post, 'recurring')
        end



      def capture(money, authorization, options = {})
      post = {}
      add_authorization(post,authorization, money)
      commit('capture', post, 'basic')
      end

      def void(authorization, options = {})
        post = {}
        add_authorization(post, authorization, nil);
        puts "########### void ################"
        puts post.inspect
        commit('void', post, 'basic')
      end

      # TODO kanechika 20140314 作成中
      #def purchase(money, creditcard, options = {})
      #  post = {}
      #  add_invoice(post, options)
      #  add_creditcard(post, creditcard)
      #  add_address(post, creditcard, options)
      #  add_customer_data(post, options)
      #
      #  commit('sale', post, 'basic')
      #end

      private

      def add_customer_data(post, options)
      end

      def add_address(post, creditcard, options)
      end

      def add_invoice(post, options)
      end

      def add_registercard(post, creditcard)
        post[:number]     = creditcard.number
        post[:holder]      = creditcard.name
        post[:expiryMonth]      = creditcard.month
        post[:expiryYear]        = creditcard.year
        post[:cardType]       = creditcard.brand
      end

      def add_authorization(post, authorization, money)
        # TODO Ayumu 2014.3.15 テストのため
        post[:transactionId] = '19102893'
        post[:transactionGuid] = '28ad07f4-037a-4802-a2ca-1fb6405ac407'
        post[:currencyId] = '840'
        post[:trackingMemberCode] = 'test8'
        post[:amount] = money
      end

      def add_recurringcard(post,recurringcard,money)
        post[:cardId] = recurringcard[:cardId]
        post[:cardGuid] = recurringcard[:cardGuid]
        post[:amount] = money
        # TODO Ayumu テストデータの
        post[:countryId] = 840
        post[:currencyId] = 840
        post[:trackingMemberCode] = 'test7'
        post[:merchantAccountType] = 1 # 1 => ? , 2 => ?, 4 => ?
        post[:dynamicDescriptor] = 'test'
        post[:avsAddress] = 'test'
        post[:avsZip] = 'test'
      end

      def add_creditcard(post, creditcard)
        post[:media]     = "cc"
        post[:name]      = creditcard.name
        post[:cc]        = creditcard.number
        post[:exp]       = expdate(creditcard)
        post[:cvv]       = creditcard.verification_value if creditcard.verification_value?
      end

      # TODO Ayumu 2014.3.14 作成が必要
      def parse(data,action,action_type)
        # 取得データ
        puts "############# data ################"
        puts data.inspect

        result = {}
        xml = Nokogiri::XML(data)
        xml.remove_namespaces!

        result_type = get_result_type(action)
        root = xml.xpath("//#{result_type}")

        # TODO Ayumu 検索方法を検討中
        #root.xpath(".//*").each do |node|
        root.children.each do |node|
          parse_element(result, node) if node.element?

          # Nodeごとのデータ
          #puts "###### node ######"
          #puts node
        end
        return result
      end

      def commit(action, post, action_type)
        # TODO Ayumu 2014.3.15 なぜ@optionsなのか
        post[:memberId] = @options[:memberId]
        post[:memberGuid] = @options[:memberGuid]
        post[:action] = action

        # payvisionにpostする

        # INPUT データ
        puts nil
        puts "########## post ############"
        puts post.inspect

        response = parse( ssl_post( action_url(action, action_type), post_data(post)), action, action_type )

        # RESPONSE データ
        #puts "########## response ###########"
        #puts response.inspect

        success = SUCCESS_TYPES.include?(response[:result])
        message = message_from(response)
        Response.new(success, message, response,
                     :test => test?
        )
      end

      def action_url(action, action_type)
        cap_action_type = get_cap_action(action_type)
        host_url = test? ? self.test_url : self.live_url
        prefix_url = eval("URL_PREFIX_#{cap_action_type}")

        puts "########## url ################"
        puts host_url + prefix_url + eval(cap_action_type)[action]
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

      # TODO Ayumu 必要か否か検討が必要
      def clean_and_stringify_params(post)
        # TCLink wants us to send a hash with string keys, and activemerchant pushes everything around with
        # symbol keys. Before sending our input to TCLink, we convert all our keys to strings and dump the symbol keys.
        # We also remove any pairs with nil values, as these confuse TCLink.
        post.keys.reverse.each do |key|
          if post[key]
            post[key.to_s] = post[key]
          end
          post.delete(key)
        end
      end

      def post_data(parameters)
        parameters.collect { |key, value| "#{key}=#{ CGI.escape(value.to_s)}" }.join("&")
      end
    end
  end
end


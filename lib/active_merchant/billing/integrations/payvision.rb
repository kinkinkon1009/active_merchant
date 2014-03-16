require File.dirname(__FILE__) + '/payvision/helper.rb'
require File.dirname(__FILE__) + '/payvision/notification.rb'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Payvision

        mattr_accessor :service_url
        self.service_url = 'https://testprocessor.payvisionservices.com/Gateway/'

        def self.notification(post)
          Notification.new(post)
        end
      end
    end
  end
end

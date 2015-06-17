# Swagger common files
require 'iron_client/monkey'
require 'iron_client/swagger'
require 'iron_client/swagger/configuration'
require 'iron_client/swagger/request'
require 'iron_client/swagger/response'
require 'iron_client/swagger/version'

# Models
require 'iron_client/models/base_object'
require 'iron_client/models/response_message'
require 'iron_client/models/delete_msg'
require 'iron_client/models/delete_msg_list'
require 'iron_client/models/message'
require 'iron_client/models/message_list'
require 'iron_client/models/single_message'
require 'iron_client/models/message_id_list'
require 'iron_client/models/message_post_data_list'
require 'iron_client/models/message_post_data'
require 'iron_client/models/queue_list'
require 'iron_client/models/queue_name'
require 'iron_client/models/subscriber'
require 'iron_client/models/subscriber_list'
require 'iron_client/models/reservation_request'
require 'iron_client/models/release'
require 'iron_client/models/touch'
require 'iron_client/models/touch_response'
require 'iron_client/models/reservation_response'
require 'iron_client/models/push_status'
require 'iron_client/models/push_status_list'
require 'iron_client/models/queue_info'
require 'iron_client/models/queue_info_response'
require 'iron_client/models/queue_data_response'
require 'iron_client/models/queue_data'
require 'iron_client/models/alert'
require 'iron_client/models/alert_list'
require 'iron_client/models/push'
require 'iron_client/models/queue_subscriber'
require 'iron_client/models/messages_request'

# APIs
require 'iron_client/api/iron_mq_api'

module IronClient
  # Initialize the default configuration
  Swagger.configuration ||= Swagger::Configuration.new
end

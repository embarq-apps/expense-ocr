# frozen_string_literal: true

$LOAD_PATH.unshift('/var/task/vendor/bundle/ruby/3.3.0')

require_relative 'mistral/chat'
require_relative 'mistral/base'

def handler(event:, context:)
  url = event['url']
  content_type = event['content_type']
  response = Mistral::Chat.new(url, content_type).call

  { statusCode: 200, body: response }
rescue Mistral::ApiError => e
  { statusCode: 500, body: e.response }
rescue StandardError => e
  { statusCode: 500, body: e.message }
end

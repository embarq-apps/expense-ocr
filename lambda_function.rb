# frozen_string_literal: true

$LOAD_PATH.unshift('/var/task/vendor/bundle/ruby/3.3.0')

require_relative 'expense_ocr'

def handler(event:, context:)
  url = event['url']
  content_type = event['content_type']
  response = ExpenseOcr.new(url, content_type).extract_data
rescue StandardError => e
  { statusCode: 500, body: e.message }
else
  { statusCode: 200, body: response, content_type: content_type, url: url }
end

# frozen_string_literal: true

$LOAD_PATH.unshift('/var/task/vendor/bundle/ruby/3.3.0')

require 'lib/expense_ocr'

def handler(event:, context:)
  url = event['url']
  doc_type = event['doc_type']
  response = ExpenseOcr.new(url, doc_type).extract_data
rescue StandardError => e
  { statusCode: 500, body: e.message }
else
  { statusCode: 200, body: response, doc_type: doc_type, url: url }
end

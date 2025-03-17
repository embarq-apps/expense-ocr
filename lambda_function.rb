# frozen_string_literal: true

$LOAD_PATH.unshift('/var/task/vendor/bundle/ruby/3.3.0')

def handler(event:, context:)
  { statusCode: 200, body: 'Hello from AWS Lambda!' }
end

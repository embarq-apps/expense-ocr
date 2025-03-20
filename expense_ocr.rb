# frozen_string_literal: true

require 'json'
require 'faraday'
require 'aws-sdk-ssm'

# ExpenseOcr analyzes documents using Mistral AI and returns the extracted information as JSON
class ExpenseOcr
  MISTRAL_API_KEY = ENV['MISTRAL_API_KEY']

  def initialize(url, content_type)
    @url = url
    @content_type = content_type
    @is_img = @content_type.include?('image/')
  end

  def extract_data
    raise "Error communicating with Mistral AI: #{chat_completions.body}" unless chat_completions.success?

    JSON.parse(chat_completions.body)['choices'][0]['message']['content']
  end

  private

  def prompt
    @prompt ||= File.read(File.join(__dir__, 'prompt.txt'))
  end

  def connection
    Faraday.new(url: 'https://api.mistral.ai') do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.headers['Content-Type'] = 'application/json'
      faraday.headers['Authorization'] = "Bearer #{MISTRAL_API_KEY || api_key}"
    end
  end

  def chat_completions
    @chat_completions ||= connection.post('/v1/chat/completions') do |req|
      req.body = body
    end
  end

  def body
    {
      model: model,
      messages: [{ role: 'user', content: content }],
      response_format: { type: 'json_object' }
    }.to_json
  end

  def content
    [
      { type: 'text', text: prompt },
      *(@is_img ? [{ type: 'image_url', image_url: @url }] : [{ type: 'document_url', document_url: @url }])
    ]
  end

  def model
    'pixtral-large-latest'
  end

  def api_key
    client = Aws::SSM::Client.new(region: 'eu-west-3')
    client.get_parameter(name: 'MISTRAL_API_KEY', with_decryption: true).parameter.value
  end
end

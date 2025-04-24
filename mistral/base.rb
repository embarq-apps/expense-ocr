# frozen_string_literal: true

require 'faraday'
require 'json'
require 'aws-sdk-ssm'

module Mistral
  # MistralApiError is raised when the Mistral API returns an error
  class ApiError < StandardError
    attr_reader :response

    def initialize(message, response = nil)
      @response = response
      super(message)
    end
  end

  # Base class for Mistral apis
  class Base
    def initialize
      @api_key = ENV['MISTRAL_API_KEY'] || api_key
    end

    private

    def response
      connection.post(route) do |req|
        req.body = request_body
      end
    end

    def connection
      Faraday.new(url: 'https://api.mistral.ai') do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.headers['Content-Type'] = 'application/json'
        faraday.headers['Authorization'] = "Bearer #{@api_key}"
      end
    end

    def api_key
      client = Aws::SSM::Client.new(region: 'eu-west-3')
      client.get_parameter(name: 'MISTRAL_API_KEY', with_decryption: true).parameter.value
    end

    def parse_json(raw_body)
      JSON.parse(raw_body)
    rescue JSON::ParserError
      { error: 'Invalid JSON response', raw_body: raw_body }
    end

    def handle_mistral_error(response_body)
      error_message = "Mistral API error#{response_body['error'] ? ": #{response_body['error']}" : ''}"
      raise Mistral::ApiError.new(error_message, response_body)
    end
  end
end

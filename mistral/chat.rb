# frozen_string_literal: true

require_relative 'base'

module Mistral
  # Chat API using Mistral AI small model
  class Chat < Base
    def initialize(url, content_type)
      super()
      # @content = content
      @url = url
      @content_type = content_type
      @is_img = @content_type.include?('image/')
      @prompt = prompt
    end

    def call
      @response = response
      response_body = parse_json(@response.body)
      handle_mistral_error(response_body) unless @response.success?
      content = JSON.parse(response_body.dig('choices', 0, 'message', 'content'))
      return content[0] if content.is_a?(Array)

      content
    end

    private

    def route
      '/v1/chat/completions'
    end

    def prompt
      File.read(File.join(__dir__, 'prompt.txt'),
                encoding: 'UTF-8', invalid: :replace,
                undef: :replace, replace: '?')
    end

    def request_body
      {
        model: model,
        messages: [
          { role: 'user',
            content: [{ type: 'text', text: "#{prompt}\n\n" },
                      document_object] }
        ],
        response_format: { type: 'json_object' }
      }.to_json
    end

    def model
      'mistral-small-latest'
    end

    def document_object
      return { type: 'document_url', document_url: @url } unless @is_img

      { type: 'image_url', image_url: @url }
    end
  end
end

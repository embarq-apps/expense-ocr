# frozen_string_literal: true

require 'dotenv/load'
require_relative 'lambda_function'

event = { 'url' => ENV['DOCUMENT_URL'], 'content_type' => ENV['DOCUMENT_TYPE'] }

p handler(event: event, context: nil)

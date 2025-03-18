# frozen_string_literal: true

$LOAD_PATH.unshift('/var/task/vendor/bundle/ruby/3.3.0')
require 'dotenv/load'
require_relative 'expense_ocr'

res = ExpenseOcr.new(
  ENV['DOCUMENT_URL'],
  ENV['DOCUMENT_TYPE']
).extract_data

p JSON.parse(res)

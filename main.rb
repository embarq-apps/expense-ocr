# frozen_string_literal: true

$LOAD_PATH.unshift('/var/task/vendor/bundle/ruby/3.3.0')
require 'dotenv/load'
require_relative 'expense_ocr'

res = ExpenseOcr.new(
  'https://embarq.s3.eu-west-3.amazonaws.com/3gxbar3cs1hyo7fvhno4izrlzwpf?response-content-disposition=inline%3B%20filename%3D%22b4043206-2418-4265-afbc-827d9c820a8e.jpeg%22%3B%20filename%2A%3DUTF-8%27%27b4043206-2418-4265-afbc-827d9c820a8e.jpeg&response-content-type=image%2Fjpeg&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAQ2YB4L75T5W5BR3B%2F20250317%2Feu-west-3%2Fs3%2Faws4_request&X-Amz-Date=20250317T151518Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=b50a0ba10ec1af0e678d3816bdcca3f02b81ec5cda13da9cbc38f75537bc2d1d',
  'image'
).analyze_document_content
p JSON.parse(res)

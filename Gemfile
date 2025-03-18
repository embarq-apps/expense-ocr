# frozen_string_literal: true

source 'https://rubygems.org'

gem 'aws-sdk-ssm'
gem 'faraday'
gem 'json'
gem 'rake'

group :development, :test do
  gem 'dotenv'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
end

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'rubocop', '~> 1.72'
  gem 'rubocop-rspec'
end

group :test do
  gem 'rspec'
end

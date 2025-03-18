# frozen_string_literal: true

require 'rubocop/rake_task'

task default: %w[test]

RuboCop::RakeTask.new(:lint) do |task|
  task.patterns = ['*.rb', 'test/**/*.rb']
  task.fail_on_error = false
end

task :run do
  ruby 'main.rb'
end

task :test do
  ruby 'test/expense_ocr_spec.rb'
end

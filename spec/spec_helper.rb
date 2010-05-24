# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
require 'rubygems'
require 'bundler'
Bundler.setup
require 'rspec'

require "#{File.dirname(__FILE__)}/../lib/active_imap"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

Rspec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # If you'd prefer not to run each of your examples within a transaction,
  # uncomment the following line.
  # config.use_transactional_examples = false
  
  config.use_transactional_examples = false
  config.color_enabled = true
  config.formatter = 'doc'
end


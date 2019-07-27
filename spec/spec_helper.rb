# frozen_string_literal: true

ENV['CAPEROMA_TEST'] = 'true'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib', 'models'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib', 'models', 'tasks'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib', 'models', 'tasks', 'modules'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'caperoma'
require 'rspec'
require 'shoulda/matchers'
require 'factory_girl'
require 'database_cleaner'
require 'timecop'
require 'aasm/rspec'
require 'byebug'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
Dir["#{File.dirname(__FILE__)}/factories/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.color = true
  config.tty = true
  config.filter_run focus: true
  config.filter_run_excluding :pending
  config.run_all_when_everything_filtered = true

  config.include(Shoulda::Matchers::ActiveModel, type: :model)
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :active_record
  end
end

I18n.enforce_available_locales = false

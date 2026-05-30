# frozen_string_literal: true

require "factory_bot"
require "tocdoc_mcp"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |file| require file }
FactoryBot.find_definitions

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.include FactoryBot::Syntax::Methods

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
end

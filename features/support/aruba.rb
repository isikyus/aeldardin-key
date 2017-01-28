require 'aruba/cucumber'

Aruba.configure do |config|
  config.activate_announcer_on_command_failure = [:stdout, :stderr]
end
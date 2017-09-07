require 'cucumber'

RSpec::Matchers.define(:warn_about) do |warning|
  match do |command|
    errors = command.stderr.split("\n")

    errors.any? do |error|
      error == "Warning: #{warning}"
    end
  end

  failure_message do |command|
    actual_warnings = command.stderr.split("\n")
    "Expected \"#{command.commandline}\" to output a warning '#{warning}' on stderr, but only saw these:\n \"#{actual_warnings}\""
  end
end

# Single quotes because we expect the warning message
# itself to contain double quotes.
Then /there should be a warning '(.*)'/ do |warning|
  expect(last_command_started).to warn_about warning
end

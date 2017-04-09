require 'cucumber'
require 'capybara'

RSpec::Matchers.define(:output_html_matching) do |matcher|
  match do |command|
    html = Capybara.string(command.output)

    values_match? matcher, html
  end
end

Then /the output should have the title "(.*)"/ do |title|
  expect(last_command_started).to output_html_matching have_selector('h1', :text => title)

  title_regexp = /<h([1-7])>#{title}<\/h\1>/
  expect(last_command_started).to have_output an_output_string_including(title)
end

Then /the output should have a section headed "(.*)"/ do |heading|
  expect(last_command_started).to output_html_matching have_selector('section h2', :text => heading)
end

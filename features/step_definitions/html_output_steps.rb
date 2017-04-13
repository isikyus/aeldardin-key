require 'cucumber'
require 'capybara'

RSpec::Matchers.define(:output_html_matching) do |matcher|
  match do |command|
    html = Capybara.string(command.output)

    values_match? matcher, html
  end

  failure_message do |command|
    "Expected \"#{command.commandline}\" to output HTML matching #{description_of(matcher)} but got \"#{command.output}\""
  end
end

Then /the output should have the title "(.*)"/ do |title|
  expect(last_command_started).to output_html_matching have_selector('h1', :text => title)

  title_regexp = /<h([1-7])>#{title}<\/h\1>/
  expect(last_command_started).to have_output an_output_string_including(title)
end

Then /the output should have a section headed "(.*)"/ do |heading|
  all_headings = %w[ h1 h2 h3 h4 h5 h6 ]
  all_section_headings = all_headings.map { |heading| "section #{heading}" }
  section_any_heading  = all_section_headings.join(', ')

  expect(last_command_started).to output_html_matching have_selector(section_any_heading, :text => heading)
end

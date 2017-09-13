require 'cucumber'
require 'capybara'

RSpec::Matchers.define(:output_html_matching) do |stream, matcher|
  match do |command|
    html = Capybara.string(command.send(stream))

    values_match? matcher, html
  end

  failure_message do |command|
    output_verb = "output"
    output_verb<< " on #{stream}" unless stream == :output
    "Expected \"#{command.commandline}\" to #{output_verb} HTML matching #{description_of(matcher)} but got \"#{command.output}\""
  end
end

Then /the (output|stdout|stderr) should have the title "(.*)"/ do |stream, title|
  expect(last_command_started).to output_html_matching stream.to_sym, have_selector('h1', :text => title)

  title_regexp = /<h([1-7])>#{title}<\/h\1>/
  expect(last_command_started).to have_output an_output_string_including(title)
end

Then /the (output|stdout|stderr) should have a section headed "(.*)"/ do |stream, heading|
  all_headings = %w[ h1 h2 h3 h4 h5 h6 ]
  all_section_headings = all_headings.map { |heading| "section #{heading}" }
  section_any_heading  = all_section_headings.join(', ')

  expect(last_command_started).to output_html_matching stream, have_selector(section_any_heading, :text => heading)
end

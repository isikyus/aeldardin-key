# File: aeldardin-to-key.rb
#
# Converts Aeldardin-Key YAML into Markdown describing the dungeon;
# this aims to be a key you could actually run the adventure from.

module Aeldardin
    class ToKey

        # @param [Aeldardin::Dungeon] dungeon The dungeon to render to Dot format.
        def initialize(dungeon)
            @dungeon = dungeon
        end

        # @param [IO] output_file The IO object to write the output .gv graph data into.
        def generateMarkdown(output_file)

            # TODO: is it better to sort by key, or by region?
            # (assuming the map is already keyed and can't be re-keyed to match the regions).
            @dungeon.rooms_by_key.each do |_key, room|

                # ## is a level-2 Markdown heading
                title = "## #{room.key}."
                title << " #{room.name}" if room.name
                output_file.puts(title)
                output_file.puts
                
                if room.description
                    output_file.puts room.description
                    output_file.puts
                end

                room.objects.each do |object|
                    
                    # * is a list item; spaces for indentation mean a list continuation.
                    output_file.puts("* #{object[:item]}")
                    
                    if object[:description]
                        output_file.puts("  #{object[:description]}")
                    end
                end

                output_file.puts
            end
        end

        private
    end
end

case ARGV.length
when 0
    input_file = STDIN
when 1
    input_file = File.open(ARGV[0], 'r')
else
    STDERR.puts "Usage: #{__FILE__} [<filename.yml>]"
    exit 1
end

require_relative 'dungeon'

dungeon = Aeldardin::Dungeon.load(input_file)
Aeldardin::ToKey.new(dungeon).generateMarkdown(STDOUT)

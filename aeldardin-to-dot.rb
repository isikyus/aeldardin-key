# File: aeldardin-to-dot.rb
#
# Script to convert Aeldardin-Key YAML files into Dot .gv files representing the connection graph of the dungeon.

module Aeldardin
    class ToDot

        # @param [Aeldardin::Dungeon] dungeon The dungeon to render to Dot format.
        def initialize(dungeon)
            @dungeon = dungeon
        end

        # @param [IO] output_file The IO object to write the output .gv graph data into.
        def generateDot(output_file)

            # Output .gv header:
            output_file.puts("graph #{safe_id(@dungeon.title)} {")

            @dungeon.rooms_by_key.each do |_key, room|

                room_name = room['name'] || room['key']

                # Output a graph edge for every exit from the room.
                # TODO: We will end up duplicating edges.
                room['exits'].each do |exit|

                    # Exit may look like '42' or { secret: '42' }
                    dest_key = exit.is_a?(Hash) ? exit.values.first : exit

                    # Use the name, rather than key, of the destination if possible.
                    # This has to match the name we use for this node elsewhere (i.e. for its exits).
                    dest_name = @dungeon.rooms_by_key[dest_key] && @dungeon.rooms_by_key[dest_key]['name'] || dest_key

                    output_file.puts("    #{node_name(room_name)} -- #{node_name(dest_name)};")
                end
            end

            # Conclude graph data
            output_file.puts('}')
        end

        private

        # Converts a key into a node name usable by dot (i.e. not starting with numbers).
        def node_name(key)
        "node_#{safe_id(key.to_s)}"
        end

        # Convert any string into something safe to use as a Dot ID (node or graph).
        # Not guaranteed to preserve uniqueness.
        def safe_id(string)
            string.gsub(/\s+/, '_').gsub(/[^A-Za-z0-9_]/, '')
        end
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
Aeldardin::ToDot.new(dungeon).generateDot(STDOUT)

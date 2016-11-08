# File: aeldardin-to-dot.rb
#
# Script to convert Aeldardin-Key YAML files into Dot .gv files representing the connection graph of the dungeon.

require 'yaml'

class AeldardinToDot
    
    # @param [IO] file The IO object to read YAML from.
    def initialize(file)
        @file = file
    end
    
    # @param [IO] output_file The IO object to write the output .gv graph data into.
    def generateDot(output_file)
        
        # Load the whole dungeon into memory at once.
        # TODO: this will fail for sufficently large dungeons.

        # 'nil' means read all lines as one row.
        yaml_text = @file.readlines(nil)[0]
        dungeon = YAML.load(yaml_text)

        # Output .gv header:
        safe_title = dungeon['title'].gsub(/\s+/, '_').gsub(/[^A-Za-z0-9_]/, '')
        output_file.puts("graph #{safe_title} {")
        
        dungeon['zones'].each do |zone|
            
            regions = zone['regions']
            
            if regions
                regions.each do |region|
                    region['rooms'].each do |room|
                    
                        # Output a graph edge for every exit from the room.
                        # TODO: We will end up duplicating edges.
                        room['exits'].each do |exit|

                            # Exit may look like '42' or { secret: '42' }
                            destination = exit.is_a?(Hash) ? exit.values.first : exit
                            output_file.puts("    #{room['key']} -- #{destination};")
                        end
                    end
                end
            else
                $stderr.puts("Found zone with no regions: #{zone['name']}")
            end
        end
        
        # Conclude graph data
        output_file.puts('}')
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

AeldardinToDot.new(input_file).generateDot(STDOUT)

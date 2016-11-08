# File: aeldardin-to-dot.rb
#
# Script to convert Aeldardin-Key YAML files into .dot files representing the connection graph of the dungeon.

require 'yaml'

class AeldardinToDot
    
    # @param [IO] file The IO object to read YAML from.
    def initialize(file)
        @file = file
    end
    
    # @param [IO] output_file The IO object to write the output 'dot' graph data to.
    def generateDot(output_file)
        
        # Load the whole dungeon into memory at once.
        # TODO: this will fail for sufficently large dungeons.

        # 'nil' means read all lines as one row.
        yaml_text = @file.readlines(nil)[0]
        yaml_data = YAML.load(yaml_text)

        output_file.write(yaml_data.keys)
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

# File: aeldardin-to-dot.rb
#
# Script to convert Aeldardin-Key YAML files into .dot files representing the connection graph of the dungeon.

class AeldardinToDot
    
    # @param [IO] file The IO object to read YAML from.
    def initialize(file)
        @file = file
    end
    
    # @param [IO] output_file The IO object to write the output 'dot' graph data to.
    def generateDot(output_file)
        output_file.write(@file.readline)
    end
end

AeldardinToDot.new(STDIN).generateDot(STDOUT)

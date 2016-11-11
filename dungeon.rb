# File: aeldardin-to-dot.rb
#
# Script to convert Aeldardin-Key YAML files into Dot .gv files representing the connection graph of the dungeon.

require 'yaml'

module Aeldardin
    class Dungeon

        # @param [IO] file The IO object to read YAML from.
        def self.load(file)

            # Load the whole dungeon into memory at once.
            # TODO: this will fail for sufficently large dungeons.

            # 'nil' means read all lines as one row.
            yaml_text = file.readlines(nil)[0]
            new(YAML.load(yaml_text))
        end

        # @param [Hash] data The dungeon data structure as described in the README, parsed into a Ruby object.
        def initialize(data)
            @data = data
        end


        # Accessor methods for dungeon properties
        # We're only interested in read-only operation for the moment.

        # The title of the overall dungeon.
        def title
            @data['title']
        end

        # The name of a specific region.
        # Conceptually different -- title is grandiose, part of the "cover of the book",
        # while name is utilitarian, summarising the region.
        # Should possibly be combined anyway.
        def name
             @data['name']
        end

        # Consider regions and zones identical, and define them recursively.
        # TODO: remove the distinct names from the data model.
        def regions

            # Use compact + flatten to combine the arrays in a nil-safe way (skip nil elements).
            [@data['zones'], @data['regions']].compact.flatten.map { |region| Dungeon.new(region) }
        end

        # Rooms part of this dungeon directly, excluding those in child regions.
        def local_rooms
           @data['rooms']
        end

        # Returns a lookup table from room keys (usually numbers) to the full room details.
        def rooms_by_key
            @rooms_by_key ||= begin
                by_key = {}

                @data['zones'].each do |zone|

                    regions = zone['regions']

                    if regions
                        regions.each do |region|
                            region['rooms'].each do |room|

                                key = room['key']

                                if by_key.key?(key)
                                    raise "Unexpected duplicate room #{key}: #{room.inspect}"
                                end

                                by_key[key] = room
                            end
                        end
                    else
                        $stderr.puts("Found zone with no regions: #{zone['name']}")
                    end
                end

                by_key
            end
        end
    end
end
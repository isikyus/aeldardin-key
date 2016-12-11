# File: aeldardin-to-dot.rb
#
# Script to convert Aeldardin-Key YAML files into Dot .gv files representing the connection graph of the dungeon.

require 'yaml'

module Aeldardin
    class Dungeon

        # Represents a room within a dungeon
        class Room

            # Based off the OD&D random-dungeon-generation room types, but
            # adjusted so each is a single room property:
            # 'empty' is an absence of other properties, and 'monster and treasure'
            # and 'trick or trap' each combine two types.
            #
            # Stored as strings rather than symbols so I can compare them to strings from user input.
            # TODO: should probably ultimately be part of an OSR-specific plugin or something.
            TYPES = %w[
                monster
                treasure
                special
                trick
                trap
            ]

            def initialize(data)
                @data = data
            end

            def key
                @data['key']
            end

            def name
                @data['name']
            end

            def description
                @data['description']
            end

            def exits
                @data['exits'] || []
            end

            # Returns a list of the objects in the room,
            # each as a hash with keys "item" (brief description), and
            # "description" (what's noticed upon investigation).
            def objects
                @objects ||= begin
                    raw_objects = @data['objects'] || []
                    raw_objects.map do |object|
                       if object.is_a?(Hash)
                           # TODO: assumes it has the right keys.
                           object
                       else
                           {
                               item: object,
                               description: nil
                           }
                       end
                    end
                end
            end

            # Similar to Gygax's room-type table in the OD&D random-dungeon rules
            # (empty, monster, monster+treasure, special, trick or trap, treasure),
            # but returns an array of types from TYPES.
            #
            # TODO: should I conver the return values to symbols?
            def types
                @data.keys & TYPES
            end
        end

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
            @regions ||= begin
                all_regions = [@data['zones'], @data['regions']]
                without_empties = all_regions.compact.flatten
                without_empties.map { |region| Dungeon.new(region) }
            end
        end

        # Rooms part of this dungeon directly, excluding those in child regions.
        def local_rooms
            @local_rooms ||= begin
                room_hashes = @data['rooms'] || []
                room_hashes.map { |hash| Room.new(hash) }
            end
        end

        # All rooms, including children.
        def rooms
            @rooms ||= begin
                child_rooms = regions.map(&:rooms).flatten
                child_rooms + local_rooms
            end
        end

        # Returns a lookup table from room keys (usually numbers) to the full room details.
        def rooms_by_key
            @rooms_by_key ||= begin
                by_key = {}

                rooms.each do |room|
                    if by_key.key?(room.key)
                        raise "Unexpected duplicate room #{room.key}: #{room.inspect}"
                    end

                    by_key[room.key] = room
                end

                by_key
            end
        end
    end
end
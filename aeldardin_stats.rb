# File: aeldardin-to-dot.rb
#
# Script to calculate statistics over the rooms in a dungeon.
require 'dungeon'

module Aeldardin
    class Stats

        def self.run
          # TODO: duplicated in Aeldardin::ToDot code.
          case ARGV.length
          when 0
              input_file = STDIN
          when 1
              input_file = File.open(ARGV[0], 'r')
          else
              STDERR.puts "Usage: #{__FILE__} [<filename.yml>]"
              exit 1
          end

          dungeon = Aeldardin::Dungeon.load(input_file)

          puts "Statistics for '#{dungeon.title}':"
          puts Aeldardin::Stats.new(dungeon).to_s
        end

        # @param [Aeldardin::Dungeon] dungeon The dungeon to render to Dot format.
        def initialize(dungeon)
            @dungeon = dungeon
        end

        # Returns a set of nested hashes mirroring the zone-and-region structure of the dungeon,
        # but containing aggregate statistics rather than adventure data.
        #
        # For now, we only calculate one thing: number of rooms.
        def stats_tree
            @stats ||= calculate(@dungeon)
        end

        # Display the statistics.
        # TODO: should probably be part of a separate presentational class.
        def to_s
            format_stats(stats_tree, '').join("\n")
        end

        private

        # Actually calculates the stats for a given dungeon, recursively.
        def calculate(dungeon)

            # Recurse. Stops when we reach regions with no children.
            recursive_stats = {}
            dungeon.regions.each do |region|
                recursive_stats[region.name] = calculate(region)
            end

            # Terminal case -- calculate stats for these rooms.

            # Create a hash where every value starts out as 0, so we can use += safely.
            local_stats = Hash.new { |h, k| h[k] = 0 }

            # Count each room for the overall total and its particular type.
            dungeon.local_rooms.each do |room|
               local_stats[:all_rooms] += 1
               local_stats[room.types] += 1
            end

            # Calculate aggregate totals by adding up counts for all types used by descendant rooms.
            aggregate_stats = Hash.new { |h, k| h[k] = 0 }

            recursive_aggregates = recursive_stats.values.map { |h| h[:aggregate] }
            (recursive_aggregates + [local_stats]).each do |child_stats|
               child_stats.each do |stat, subtotal|
                  aggregate_stats[stat] += subtotal
               end
            end

            # Build and return the result:
            {
                :regions => recursive_stats,
                :local => local_stats,
                :aggregate => aggregate_stats
            }
        end

        # Recursively format the dungeon statistics.
        # @param tree [Hash] The stats tree, as returned by (#see calculate)
        # @param indent [String] The indentation prefix -- two spaces are appended for each nesting level.
        def format_stats(tree, indent)
            stats_strings = []

            tree[:regions].each do |name, details|

                # Recurse. Again, base case is when we have no child regions.
                child_indent = indent + '  '
                child_stats = format_stats(details, child_indent)

                stats_strings << "#{indent}#{name}:"
                stats_strings += child_stats
            end

            # Format our local and aggregate stats.
            # TODO: needs to be more flexible.

            # Only show local count if present
            if tree[:local][:all_rooms] > 0
                stats_strings << "#{indent}#{format_room_counts(tree[:local])} locally"
            end

            # Only show aggregate count if there were rooms in child regions
            if tree[:aggregate][:all_rooms] != tree[:local][:all_rooms]
                stats_strings << "#{indent}#{format_room_counts(tree[:aggregate])}"
            end

            stats_strings
        end

        # Format a particular set of room statistics, showing counts by type and overall.
        # @param [Hash{Object, Integer}] A hash from arrays of room types to totals, with an extra symbol key (:all_rooms) for the overall total.
        def format_room_counts(counts)

            # Format the counts for individual room types.
            type_total_keys = counts.keys - [:all_rooms]
            type_total_strings = type_total_keys.map do |key|

                # Special case for empty rooms, as that type can't be inferred from the type array.
                total_name = (key == []) ? 'empty' : key.join('+')

                # Like '17 monster+treasure
                "#{counts[key]} #{total_name}"
            end

            "#{counts[:all_rooms]} rooms (#{type_total_strings.join(', ')})"
        end
    end
end

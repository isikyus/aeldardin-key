# File: aeldardin-to-dot.rb
#
# Script to calculate statistics over the rooms in a dungeon.

module Aeldardin
    class Stats

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
            format_stats(stats_tree, '')
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
            puts local_stats.inspect
            puts aggregate_stats.inspect
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
            formatted_regions = tree[:regions].map do |name, details|

                # Recurse. Again, base case is when we have no child regions.
                child_indent = indent + '  '
                child_stats = format_stats(details, child_indent)
                "#{indent}#{name}: #{child_stats}"
            end

            # Format our local and aggregate stats.
            # TODO: needs to be more flexible.

            # Only show local count if present; only show aggregate if there are children to count.
            local_stats = "#{indent}#{tree[:local][:all_rooms]} rooms locally" if tree[:local][:all_rooms] > 0
            aggregate_stats = "#{indent}#{tree[:aggregate][:all_rooms]} rooms" if tree[:aggregate][:all_rooms] != tree[:local][:all_rooms]


            [
                formatted_regions.flatten,
                local_stats,
                aggregate_stats
            ].join("\n")
        end
    end
end

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

require_relative 'dungeon'

dungeon = Aeldardin::Dungeon.load(input_file)

puts "Statistics for '#{dungeon.title}':"
puts Aeldardin::Stats.new(dungeon).to_s

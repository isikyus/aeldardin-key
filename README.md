
# Aeldardin Key

(Tools to work with) a YAML format for dungeon keys, designed for use with D&D and similar roleplaying games. 

This is a companion project to Aeldardin Rooms.
Whereas that app aims to represent dungeon _layouts_ in a machine-readable way,
this one models and processes dungeon _keys_.

## Usage:

Convert to a .dot graph:

    ruby aeldardin-to-dot.rb dungeon.yml > output.dot

Calculate dungeon statistics (room counts):

    ruby room_statistics.rb dungeon.yml

## Rationale

Why is this worth doing?
It is, after all, a lot of effort to type up a dungeon key in a strict format like this.

Two things motivate me to build this:

Firstly, Dungeons keys are fundamentally structured data (see Peter Alexandrian's series on writing them).
Since I'm obsessed with style-and-content separation, I want to work on the structure -- the _dungeon itself_ -- and not worry about formatting (how big should this heading be?) or structure (where should I put stat blocks?) until it comes time to publish the dungeon.

Using a machine-readable format lets me automatically generate the final layout when the time comes, without having to decide on it ahead of time.

Which brings me to my second point: if you can generate multiple layouts, you can pick a layout that emphasises one particular aspect of the dungeon.

For instance (and this is my first goal for the project), a graph showing room connections, which emphasises how the dungeon is structured.

## Data Format

This is a rough description of the YAML format I'm using.
TODO: write up a formal schema of some kind.

* `title` (string): The title of the adventure
* `blurb` (text): Summary of what the adventure is about
* `monster`: Details of a particular monster. Exact format depends on the particular game you're writing for.
* `zone`: A region of the dungeon (e.g. level) (TODO: make this the same as `region`, so we can have a recursive structure):
  * `id` (id): A machine-readable name for the zone, to allow references from elsewhere in the document.
  * `name` (string)
  * `encounters` (array): A random-encounter table for the zone. Could contain `monster` tags, or just text descriptions.
  * `connections`: Ways to travel out of this zone (only really useful for wilderness, etc. without distinct rooms):
    * `key` (id): Machine-readable, unique name for use elsewhere.
    * `to` (idref): ID of the zone the connection leads to. (Not the exact room, which is determined by the exits list in the zone).
    * `description` (text)
  * `region` (array): An area of the zone with mapped dungeon rooms
    * `name` (string): Descriptive name of the region
    * `rooms` (array):
      * `key` (id): Map key number of the room. Must be unique within a zone (TODO: why this scope?)
      * `name` (string): Descriptive room name. Optional.
      * `exits` (array): Exits of the room. Array elements may be bare strings (interpreted as destination keys), or pairs like `<secret>: 22`, where `<secret>` is a reason the passage is hard to traverse (also blocked, concealed, narrow, etc.), and `22` is the key of the destination room.
      * `monster` (array): Array of monster details.
      * `treasure` (array): Array of valuable items there for the taking. Items carried by monsters should be sub-keys on the relevant `monster` entries.
        * `item` (string): Name of the item.
        * `coin` (denomination): Denomination of coin. `item` is unnecessary in this case.
        * `quantity` (number-or-die-roll): Number of this item in the room/carried by the monster.
        * `value` (number-or-die-roll): Value of one item (or of the whole lot of no quantity specified -- e.g. for coins).
      * `trap` (array): Array of trap descriptions.
      * `description`: Text description of the room, excluding details that would go on one of the above keys.
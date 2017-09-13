Feature: Convert key YAML files to HTML dungeon keys

  The core functionality of Aeldardin Key: take the YAML-formatted key,
  and convert it into a nice-looking HTML key that can be shared online
  or used to actually run the adventure.

  Background:
    Given a file named "dungeon.yml" with:
    """
    #%YAML 1.2
    ---
    title: Test Dungeon

    zones:
    - id: basement1
      name: Basement One
      rooms:
      - key: entrance
        name: Main Entrance
        description: >
          A flight of broad black-granite steps lead down into this low hall.
        exits:
        - surface
        - storeroom
        - hallway
        - guardroom
      - key: storeroom
        name: Storage Room
        description: >
          This storeroom is piled high with crates, most rotted open and empty.
        objects:
          - item: Large box
            description: This large box alone is still sealed.
          - Small, rotted box
          - Rotted barrel
        exits:
        - entrance
      - key: hallway
        name: Hallway
        exits:
        - guardroom
        - entrance
      - key: guardroom
        name: Guard Room
        description: Some guards wait here.
        monster:
          stats:
            name: Hired Guard
            description: A guard in a breastplate and pointed steel helmet, carrying a spear.
          number: 2d3
          disposition: Peaceful until  what they guard is disturbed.
        exits:
        - hallway
        - entrance
        - basement2
    """

  Scenario: Heading Structure
    When I successfully run `aeldardin html dungeon.yml`
    Then the output should have the title "Test Dungeon"
    And the output should have a section headed "Basement One"
    And the output should have a section headed "Main Entrance"
    And the output should have a section headed "Storage Room"
    And the output should have a section headed "Hallway"
    And the output should have a section headed "Guard Room"
    

Feature: Convert key YAML files to dot graphs

  This is a fairly simple dungeon visualisation;
  it generates a .dot file which can be viewed with
  `dot` as a graph of the dungeon -- circles for rooms,
  and arrows for the connections between them.

  It's mainly here for testing, but it can also give you
  an idea of the large-scale structure of your dungeon:
  where chokepoints, hubs, and dead ends are, and
  what obstacles stand between the PCs and a particular
  objective.

  Background:
    Given a file named "dungeon.yml" with:
    """
    #%YAML 1.2
    ---
    title: Test Dungeon

    zones:
    - id: level1
      name: Basement One
      rooms:
      - key: entrance
        name: Main Entrance
        exits:
        - surface
        - storeroom
        - hallway
        - guardroom
      - key: storeroom
        name: Storage Room
        exits:
        - entrance
      - key: hallway
        name: Hallway
        exits:
        - guardroom
        - entrance
      - key: guardroom
        name: Guard Room

        exits:
        - hallway
        - entrance
        - basement2
    """

  Scenario: Using Ruby implementation
    When I successfully run `aeldardin-to-dot dungeon.yml`
    Then the output should contain exactly:
    """
    graph Test_Dungeon {
        node_Main_Entrance -- node_surface;
        node_Main_Entrance -- node_Storage_Room;
        node_Main_Entrance -- node_Hallway;
        node_Main_Entrance -- node_Guard_Room;
        node_Storage_Room -- node_Main_Entrance;
        node_Hallway -- node_Guard_Room;
        node_Hallway -- node_Main_Entrance;
        node_Guard_Room -- node_Hallway;
        node_Guard_Room -- node_Main_Entrance;
        node_Guard_Room -- node_basement2;
    }
    """
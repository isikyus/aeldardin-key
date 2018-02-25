module GraphvizExport exposing (all)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String

import GraphvizParser exposing (validId, expectValidGraphviz)

import Dungeon as D
import Export.Graphviz

-- Dungeon fuzzer definition -- TODO: extract this to its own file.
roomWithNameAndExits : String -> List String -> D.Room
roomWithNameAndExits name exits =
  D.Room
    -- Use name as key too -- one is supposed to be human-readable,
    -- the other succinct, but we don't care about either for this test.
    name
    name
    Nothing
    ( List.map
      (\exit -> D.Connection "door" exit)
      exits
    )

-- Creates a dungeon with a room using each given name,
-- which is "fully connected" -- every room connects to every other.
dungeonWithRoomsNamed : List String -> D.Dungeon
dungeonWithRoomsNamed names =
  D.Dungeon
    "Test Dungeon with rooms for names"
    [ D.Zone
      "1"
      Nothing
      ( List.map
        -- Create exits to every other room, including this one
        -- (since we don't skip this room's name)
        (\name -> roomWithNameAndExits name names)
        names
      )
      (D.Regions [])
    ]

dungeon : Fuzz.Fuzzer D.Dungeon
dungeon =
  Fuzz.map
    dungeonWithRoomsNamed
    (Fuzz.list Fuzz.string)


all : Test
all =
  describe "Graphviz export"
    [ -- Un-quoted Graphviz identifiers are limited to alphanumerics + _,
      -- and either start with a non-numeral (like C identifiers)
      -- or consist only of numerals.
      -- TODO: avoid all this by using _quoted_ identifiers instead.
      fuzz string "Graph title only contains 'identifier' characters" <|
        \title -> D.Dungeon (String.cons '_' title) []
          |> Export.Graphviz.toGraphviz
          |> expectValidGraphviz

    , fuzz dungeon "Node names only contain 'identifier' characters" <|
        \d -> Export.Graphviz.toGraphviz d
          |> expectValidGraphviz

    , fuzz3 validId validId validId "All edges are represented in the output graph" <|
        \node1 -> \node2 -> \node3 ->

          -- Pass in rooms names in reverse order, since the graph is generated backwards.
          dungeonWithRoomsNamed [node3, node2, node1]
          |> Export.Graphviz.toGraphviz
          |>
            \graph ->
              Expect.equal
                graph
                ( "graph Test_Dungeon_with_rooms_for_names {\n"
                  ++ "    node_" ++ node1 ++ " -- node_" ++ node1 ++ ";\n"
                  ++ "    node_" ++ node1 ++ " -- node_" ++ node2 ++ ";\n"
                  ++ "    node_" ++ node1 ++ " -- node_" ++ node3 ++ ";\n"
                  ++ "    node_" ++ node2 ++ " -- node_" ++ node1 ++ ";\n"
                  ++ "    node_" ++ node2 ++ " -- node_" ++ node2 ++ ";\n"
                  ++ "    node_" ++ node2 ++ " -- node_" ++ node3 ++ ";\n"
                  ++ "    node_" ++ node3 ++ " -- node_" ++ node1 ++ ";\n"
                  ++ "    node_" ++ node3 ++ " -- node_" ++ node2 ++ ";\n"
                  ++ "    node_" ++ node3 ++ " -- node_" ++ node3 ++ ";\n"
                  ++ "}"
                )
    ]

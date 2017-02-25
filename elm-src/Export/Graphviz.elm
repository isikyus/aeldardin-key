module Export.Graphviz exposing (toGraphviz)

import Dungeon exposing (..)

-- Convert a dungeon to Graphviz's .gv format (which can then be rendered as an image)
toGraphviz : Dungeon -> String
toGraphviz dungeon =
  "graph " ++ (toIdentifier dungeon.title) ++ " {\n" ++
  ( List.foldl
      String.append
      ""
      ( List.concatMap
        toEdges
        (Dungeon.rooms dungeon)
      )
  ) ++
  "}"


-- Convert a the exits of a room to a series of strings representing Graphviz edges.
toEdges : Room -> List String
toEdges room =
  List.map
    (\exit -> edge room.key exit.destination)
    room.exits


-- Generate Graphviz notation for an edge between two named nodes.
edge : String -> String -> String
edge start end =
  "    " ++ start ++ " -- " ++ end ++ ";\n"

-- Convert a string to a valid Graphviz identifier,
-- by replacing spaces with underscores.
--
-- Modified from the String.map example at http://package.elm-lang.org/packages/elm-lang/core/latest/String ,
-- which is copyright Evan Czaplicki.
-- TODO: should also handle other non-identifier characters.
-- TODO: not guaranteed to preserve uniqueness
toIdentifier : String -> String
toIdentifier string =
  String.map
    (\c -> if c == ' ' then '_' else c)
    string
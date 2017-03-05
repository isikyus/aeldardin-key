module Export.Graphviz exposing (toGraphviz)

import Dungeon exposing (..)

-- Needed to escape node names
import Regex

-- Convert a dungeon to Graphviz's .gv format
-- (which can then be rendered as an image)
toGraphviz : Dungeon -> String
toGraphviz dungeon =
  "graph " ++ (toIdentifier dungeon.title) ++ " {\n" ++
    ( List.foldl
      String.append
      ""
      (List.concatMap allExitsToEdges dungeon.zones)
    ) ++
  "}"


-- Generate all edge declarations for exits of rooms in a given zone.
allExitsToEdges : Zone -> List String
allExitsToEdges zone =
  List.concatMap
    (\room -> exitsToEdges room zone)
    (Dungeon.localRooms zone)


-- Convert a the exits of a room to a series of strings,
-- representing Graphviz edges.
-- Takes the containing zone as well, so we can show room names.
exitsToEdges : Room -> Zone -> List String
exitsToEdges room zone =
  List.map
    ( \exit ->
      edge
        ( toIdentifier ("node_" ++ room.name) )
        ( toIdentifier
          ( "node_"
            ++ (nameForKey exit.destination zone)
          )
        )
    )
    room.exits


-- Try to find the correct name for a given room key.
nameForKey : String -> Zone -> String
nameForKey key scope =
  case (Dungeon.findRoom key scope) of
    Nothing ->
      key

    Just room ->
      room.name


-- Generate Graphviz notation for an edge between two named nodes.
edge : String -> String -> String
edge start end =
  "    " ++ start ++ " -- " ++ end ++ ";\n"


-- Convert a string to a valid Graphviz identifier,
-- by replacing spaces with underscores.
--
-- Modified from the String.map example at
-- http://package.elm-lang.org/packages/elm-lang/core/latest/String ,
-- which is copyright Evan Czaplicki.
--
-- TODO: should also handle other non-identifier characters.
-- TODO: not guaranteed to preserve uniqueness
toIdentifier : String -> String
toIdentifier string =
  Regex.replace
    Regex.All
    (Regex.regex "[^A-Za-z0-9_]")
    (\c -> "_")
    string
module Export.Graphviz exposing (toGraphviz)

import Dungeon exposing (..)

-- Convert a dungeon to Graphviz's .gv format (which can then be rendered as an image)

toGraphviz : Dungeon -> String
toGraphviz dungeon =
  "graph " ++ dungeon.title ++ " { }"
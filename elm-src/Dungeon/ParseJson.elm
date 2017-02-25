module Dungeon.ParseJson exposing (decodeDungeon)

-- Code that knows how to parse dungeons from JSON,
-- including resolving the shorthand syntaxes we allow in the raw YAML key.

import Dungeon exposing (..)
import Json.Decode exposing (..)

dungeon = map2 Dungeon
        (field "title" string)
        (field "zones" (list zone))

zone = map2 Zone
        (field "rooms" (list room))
        (oneOf [ field "regions" regions, succeed (Regions []) ])

regions = map Regions (list (lazy (\_ -> zone)))
room = succeed Room

decodeDungeon : String -> Result String Dungeon
decodeDungeon jsonString =
  decodeString dungeon jsonString
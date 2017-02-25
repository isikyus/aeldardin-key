module Dungeon.ParseJson exposing (decodeDungeon)

-- Code that knows how to parse dungeons from JSON,
-- including resolving the shorthand syntaxes we allow in the raw YAML key.

import Dungeon exposing (Dungeon)
import Json.Decode exposing (..)

dungeonDecoder = map Dungeon ( field "title" string )

decodeDungeon : String -> Result String Dungeon
decodeDungeon jsonString =
  decodeString dungeonDecoder jsonString
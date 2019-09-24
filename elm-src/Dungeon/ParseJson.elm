module Dungeon.ParseJson exposing (decodeDungeon, decodeWithUnusedFields)

-- Code that knows how to parse dungeons from JSON,
-- including resolving the shorthand syntaxes we allow in the raw YAML key.

import Dict
import Dungeon exposing (..)
import Parser.DecodeStrictly exposing (..)
import Json.Decode

-- An optional field with an array value.
-- If the field is present, this will decode it as a list;
-- if missing, it will default to [] in the decoded object.
optionalListField : String -> Decoder a -> Decoder (List a)
optionalListField name decoder =
  map
    ( Maybe.withDefault [] )
    ( optionalField
        name
        (list decoder)
    )

dungeon : Decoder Dungeon
dungeon =
  map2 Dungeon
    (field "title" string)
    (optionalListField "zones" zone)

zone : Decoder Zone
zone =
  map4 Zone
    ( field "id" stringOrInt )
    ( optionalField "name" string )
    ( optionalListField "rooms" room )
    ( map
        Regions
        ( optionalListField
            "regions"
            (lazy (\_ -> zone))
        )
    )


-- Decode strings directly, but convert numbers to strings.
stringOrInt : Decoder String
stringOrInt =
  oneOf
    [ map toString int
    , string
    ]

room : Decoder Room
room =
  map4 Room
    (field "key" stringOrInt)
    (field "name" string)
    (optionalField "description" string)
    (optionalListField "exits" exit)


-- Exits can be a bare <key>, or a hash like { to: <key>, type: <type>, etc.}, where <type>
-- is an arbitrary string describing how the exit works (door, secret, "magical portal", etc.)
-- In the former case, the type is assumed to be "door".
exit : Decoder Connection
exit =
  oneOf
    [ map2 Connection (succeed "door") stringOrInt
    , map2
        Connection
        ( map
          ( Maybe.withDefault "door" )
          ( optionalField "type" string )
        )
        (field "to" stringOrInt)
    ]

-- Decode the dungeon, treating unused fields as errors (i.e. crashing on them)
-- TODO: should validate room IDs are unique.
decodeDungeon : String -> Result Failure Dungeon
decodeDungeon jsonString =
  decodeString dungeon jsonString

-- As above, but return unused fields as a separate list.
decodeWithUnusedFields : String -> Result String (Dungeon, UnusedFields )
decodeWithUnusedFields =
  Json.Decode.decodeString (withUnusedFields dungeon)

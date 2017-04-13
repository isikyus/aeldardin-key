module Dungeon.ParseJson exposing (decodeDungeon)

-- Code that knows how to parse dungeons from JSON,
-- including resolving the shorthand syntaxes we allow in the raw YAML key.

import Dict
import Dungeon exposing (..)
import Json.Decode exposing (..)

-- An optional field with an array value.
-- If the field is present, this will decode it as a list;
-- if missing, it will default to [] in the decoded object.
optionalListField : String -> Decoder a -> Decoder (List a)
optionalListField name decoder =
  dict Json.Decode.value
    |> Json.Decode.andThen
        ( \values -> Dict.get name values

            -- If value exists, apply the given decoder.
            |> Maybe.map (decodeValue (list decoder))

            -- Otherwise, decode to an empty list.
            |> Maybe.withDefault (Ok [])

            -- If the nested decoding failed, pass up the failure.
            |> \decoded -> case decoded of
                                Ok result ->
                                  succeed result
                                Err message ->
                                  fail message
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
    ( maybe ( field "name" string ) )
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
  map3 Room
    (field "key" stringOrInt)
    (field "name" string)
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
          ( maybe
            (field "type" string)
          )
        )
        (field "to" stringOrInt)
    ]

-- TODO: should validate room IDs are unique.
decodeDungeon : String -> Result String Dungeon
decodeDungeon jsonString =
  decodeString dungeon jsonString

module Dungeon.ParseJson exposing (decodeDungeon)

-- Code that knows how to parse dungeons from JSON,
-- including resolving the shorthand syntaxes we allow in the raw YAML key.

import Dungeon exposing (..)
import Json.Decode exposing (..)

dungeon : Decoder Dungeon
dungeon =
  map2 Dungeon
    (field "title" string)
    (field "zones" (list zone))

zone : Decoder Zone
zone =
  map2 Zone
    (field "rooms" (list room))
    (oneOf
      [ field "regions" regions
      , succeed (Regions [])
      ]
    )

regions : Decoder Regions
regions = map Regions (list (lazy (\_ -> zone)))

room : Decoder Room
room =
  map3 Room
    (field "key" string)
    (field "name" string)
    (field "exits" (list exit))


-- Helper function: decode a one-element list to that one element, and fail on other lists.
unwrapSingleton : List a -> Decoder a
unwrapSingleton list =
  case list of
    [] ->

      fail "Expected a one-field object for door type, got an empty one"

    [ element ] ->
      succeed element

    first :: second :: rest ->
      fail "Expected a one-field object for door type, got two or more fields"


-- Exits can be a bare <key>, or a pair like <type>: <key>, where <type>
-- is an arbitrary string describing how the exit works (door, secret, "magical portal", etc.)
-- In the former case, the type is assumed to be "door".
exit : Decoder Connection
exit =
  oneOf
    [ map2 Connection (succeed "door") string
    , let

        -- Build a connection from a pair of arguments.
        -- TODO: surely there's a cleaner way to do this?
        connectionFromPair : ( String, String ) -> Connection
        connectionFromPair (doorType, dest) =
                Connection doorType dest
      in
        map
          connectionFromPair
          ( keyValuePairs string
            |> andThen unwrapSingleton
          )
    ]

-- TODO: should validate room IDs are unique.
decodeDungeon : String -> Result String Dungeon
decodeDungeon jsonString =
  decodeString dungeon jsonString
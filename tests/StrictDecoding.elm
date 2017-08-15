module StrictDecoding exposing (all)

import Test exposing (..)
import Expect
import Fuzz exposing (string, bool, int, float)

import Regex as R
import Set

import Parser.DecodeStrictly as Decode

escapeForJson : String -> String
escapeForJson string =
  ( R.replace
      R.All
      -- \\\\ means a single backslash -- escaped once for the Elm string,
      -- and a second time for the regular expression engine.
      (R.regex "\"|\\\\")
      (\match -> "\\" ++ match.match)
      string
  )

boolToJson : Bool -> String
boolToJson value =
  case value of
      True ->
        "true"
      False ->
        "false"


all : Test
all =
    describe "Parsing JS objects and checking for unused fields"
      [ fuzz2 string string "Parses an expected field successfully" <|
        \field -> \value -> "{\"" ++ (escapeForJson field) ++ "\":\"" ++ (escapeForJson value) ++ "\"}"
          |> Decode.decodeString (Decode.field field Decode.string)
          |> Expect.equal (Ok value)

      , fuzz2 string bool "Parses a boolean field successfully" <|
        \field -> \value -> "{\"" ++ (escapeForJson field) ++ "\":" ++ (boolToJson value) ++ "}"
          |> Decode.decodeString (Decode.field field Decode.bool)
          |> Expect.equal (Ok value)

      , fuzz2 string int "Parses an integer field successfully" <|
        \field -> \value -> "{\"" ++ (escapeForJson field) ++ "\":" ++ (toString value) ++ "}"
          |> Decode.decodeString (Decode.field field Decode.int)
          |> Expect.equal (Ok value)

      , fuzz2 string float "Parses a floating-point field successfully" <|
        \field -> \value -> "{\"" ++ (escapeForJson field) ++ "\":" ++ (toString value) ++ "}"
          |> Decode.decodeString (Decode.field field Decode.float)
          |> Expect.equal (Ok value)

      , fuzz3 string string string "Fails to parse an unexpected field" <|
        \field -> \value -> \extraField ->
          "{\"" ++ (escapeForJson field) ++ "\":\"" ++ (escapeForJson value) ++
            "\",\"" ++ (escapeForJson extraField) ++ "\":\"Extra Value\"}"
          |> Decode.decodeString (Decode.field field Decode.string)
          |> ( Expect.equal
                ( Err
                  ( Decode.Unused (Set.singleton [extraField]) )
                )
             )
      ]

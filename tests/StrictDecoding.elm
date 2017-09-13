module StrictDecoding exposing (all)

import Test exposing (..)
import Expect
import Fuzz exposing (string, bool, int, float)

import Regex as R
import Set
import Dict

import Parser.DecodeStrictly as Decode

escapeForJson : String -> String
escapeForJson =
  let
    escapeSpecialChar : Char -> String
    escapeSpecialChar char =
      case char of
          -- List of control characters from http://www.json.org/
          '\"' -> "\\\""
          '\\' -> "\\\\"
          '/' -> "\\/"
          '\b' -> "\\b"
          '\f' -> "\\f"
          '\n' -> "\\n"
          '\r' -> "\\r"
          '\t' -> "\\t"

          _ ->
            ( String.fromChar char )
  in
    String.foldr
      (\char -> \string ->
        ( escapeSpecialChar char ) ++ string
      )
      ""

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
        \field -> \value -> \suffix ->
          let
              -- Ensure the unused field name is different to the actual field of interest.
              -- Need the _ in case field and suffix are empty strings.
              unusedFieldName = field ++ "_" ++ suffix
          in
            "{\"" ++ (escapeForJson field) ++ "\":\"" ++ (escapeForJson value) ++
              "\",\"" ++ (escapeForJson unusedFieldName) ++ "\":\"Extra Value\"}"
            |> Decode.decodeString (Decode.field field Decode.string)
            |> ( Expect.equal
                  ( Err
                    ( Decode.Unused (Set.singleton [unusedFieldName]) )
                  )
              )

      , fuzz2 string string "Parses a nested field" <|
        \key -> \subkey ->
          "{\"" ++ (escapeForJson key) ++ "\":" ++
            "{\"" ++ (escapeForJson subkey) ++ "\":22}" ++
          "}"
          |> ( Decode.decodeString
                ( Decode.field key (Decode.field subkey Decode.int) )
             )
          |> ( Expect.equal (Ok 22) )

      , fuzz3 string string string "Fails on an unused nested field" <|
        \key -> \subkey -> \suffix ->
          let
              -- Ensure the unused field name is different to the actual field of interest.
              -- Need the _ in case subkey and suffix are empty strings.
              unusedFieldName = subkey ++ "_" ++ suffix
          in
            "{\"" ++ (escapeForJson key) ++ "\":" ++
              "{\"" ++ (escapeForJson subkey) ++ "\":22" ++
              ",\"" ++ (escapeForJson unusedFieldName) ++ "\":0" ++
              "}" ++
            "}"
            |> ( Decode.decodeString
                  ( Decode.field key (Decode.field subkey Decode.int) )
              )
            |> ( Expect.equal
                  ( Err
                    ( Decode.Unused (Set.singleton [key, unusedFieldName]) )
                  )
               )

      , fuzz3 string string string "Parses a valid list successfully" <|
        \key -> \item1 -> \item2 ->
            "{\"" ++ (escapeForJson key) ++ "\":" ++
              "[\"" ++ (escapeForJson item1) ++ "\"" ++
              ",\"" ++ (escapeForJson item2) ++ "\"" ++
              "]" ++
            "}"
            |> ( Decode.decodeString
                  ( Decode.field key (Decode.list Decode.string) )
              )
            |> Expect.equal ( Ok [item1, item2] )

      , fuzz3 string string string "Combines unused fields from an invalid list" <|
        \key -> \unused1 -> \unused2 ->
            "{\"" ++ (escapeForJson key) ++ "\":" ++
              "[ {\"" ++ (escapeForJson unused1) ++ "\": 1}" ++
              ", {\"" ++ (escapeForJson unused2) ++ "\": 2}" ++
              "]" ++
            "}"
            |> ( Decode.decodeString
                  ( Decode.field
                    key
                    ( Decode.list (Decode.succeed 0) )
                  )
               )
            |> ( Expect.equal
                  ( Err
                    ( Decode.Unused
                      ( Set.empty
                        |> Set.insert [key, unused1]
                        |> Set.insert [key, unused2]
                      )
                    )
                  )
               )

      , fuzz2 string string "Lazy decoding works" <|
        \key -> \value ->
            "{\"" ++ (escapeForJson key) ++ "\":\"" ++ (escapeForJson value) ++ "\"}"
            |> ( Decode.decodeString
                  ( Decode.lazy (\_ -> Decode.field key Decode.string) )
              )
            |> Expect.equal ( Ok value )

      , fuzz2 string string "Lazy decoding propogates unused fields" <|
        \key -> \value ->
            "{\"" ++ (escapeForJson key) ++ "\":\"" ++ (escapeForJson value) ++ "\"}"
            |> ( Decode.decodeString
                  ( Decode.lazy
                    (\_ -> Decode.succeed "used nothing")
                  )
              )
            |> ( Expect.equal
                  ( Err
                    ( Decode.Unused
                      ( Set.singleton [key] )
                    )
                  )
               )

      , fuzz3 string string string "Fails when using only some of multiple fields" <|
        \field -> \nested -> \unused ->
            "{\"" ++ (escapeForJson field) ++ "_singleton\": \"a\"" ++
            ",\"" ++ (escapeForJson field) ++ "_list\": [\"b\", \"1\"]" ++
            ",\"" ++ (escapeForJson field) ++ "_object\":" ++
                "{\"" ++ (escapeForJson nested) ++ "\": \"c\"" ++
                ",\"_" ++ (escapeForJson unused) ++ "\": \"see\"" ++
                "}" ++
            ",\"" ++ (escapeForJson unused) ++ "\": \"d\"" ++
            "}"
            |> ( Decode.decodeString
                  -- Return the two parsed fields as a pair.
                  ( Decode.map3
                    (,,)
                    ( Decode.field (field ++ "_singleton") Decode.string )
                    ( Decode.field
                        (field ++ "_list")
                        (Decode.list Decode.string)
                    )
                    ( Decode.field
                        (field ++ "_object")
                        (Decode.field nested Decode.string)
                    )
                  )
              )
            |> ( Expect.equal
                  ( Err
                    ( Decode.Unused
                      ( Set.empty
                        |> Set.insert [unused]
                        |> Set.insert [field ++ "_object", "_" ++ unused]
                      )
                    )
                  )
               )

      , fuzz string "Succeeds when multiple fields are all used" <|
        \field ->
            "{\"" ++ (escapeForJson field) ++ "_1\": \"a\"" ++
            ",\"" ++ (escapeForJson field) ++ "_2\": \"b\"" ++
            "}"
            |> ( Decode.decodeString
                  -- Return the two parsed fields as a pair.
                  ( Decode.map2
                    (,)
                    ( Decode.field (field ++ "_1") Decode.string )
                    ( Decode.field (field ++ "_2") Decode.string )
                  )
              )
            |> Expect.equal ( Ok ("a","b") )

      , fuzz string "Succeeds when four fields are all used" <|
        \field ->
            "{\"" ++ (escapeForJson field) ++ "_1\": \"a\"" ++
            ",\"" ++ (escapeForJson field) ++ "_2\": \"b\"" ++
            ",\"" ++ (escapeForJson field) ++ "_3\": \"c\"" ++
            ",\"" ++ (escapeForJson field) ++ "_4\": \"d\"" ++
            "}"
            |> ( Decode.decodeString
                  -- Return the four parsed fields as a 4-tuple.
                  ( Decode.map4
                    (,,,)
                    ( Decode.field (field ++ "_1") Decode.string )
                    ( Decode.field (field ++ "_2") Decode.string )
                    ( Decode.field (field ++ "_3") Decode.string )
                    ( Decode.field (field ++ "_4") Decode.string )
                  )
              )
            |> Expect.equal ( Ok ("a","b","c","d") )

        -- Not a priority to support dict because we can't tell which fields are used.
--       , fuzz string "Assumes all fields are used when decoding to dict" <|
--         \field ->
--             "{\"" ++ (escapeForJson field) ++ "_1\": \"a\"" ++
--             ",\"" ++ (escapeForJson field) ++ "_2\": \"b\"" ++
--             "}"
--             |> Decode.decodeString (Decode.dict Decode.string)
--             |> ( Expect.equal
--                  ( Dict.empty
--                    |> Dict.insert (field ++ "_1") "a"
--                    |> Dict.insert (field ++ "_2") "b"
--                  )
--                )

      , fuzz2 string int "optionalField returns and consumes a field if present" <|
        \field -> \value -> "{\"" ++ (escapeForJson field) ++ "\":" ++ (toString value) ++ "}"
          |> Decode.decodeString (Decode.optionalField field Decode.int)
          |> Expect.equal (Ok (Just value))

      , fuzz string "optionalField returns nothing if the field is not present" <|
          \field -> "{}"
            |> Decode.decodeString (Decode.optionalField field Decode.int)
            |> Expect.equal (Ok Nothing)

      , fuzz string "optionalField fails on unused fields as normal" <|
        \field ->
          let
              wrongFieldName = "_" ++ field
          in
            "{\"" ++ (escapeForJson wrongFieldName) ++ "\":0}"
              |> Decode.decodeString (Decode.optionalField field Decode.int)
              |>  ( Expect.equal
                    ( Err
                      ( Decode.Unused (Set.singleton [wrongFieldName]) )
                    )
                  )

      , fuzz string "optionalField does not swallow inner failures" <|
        \field ->
          "{\"" ++ (escapeForJson field) ++ "\":0}"
            |> ( Decode.decodeString
                  ( Decode.optionalField field (Decode.fail "fake error") )
                )
            |>  ( Expect.equal
                  ( Err
                    ( Decode.InvalidJson
                      ("I ran into a `fail` decoder at _." ++ field ++ ": fake error")
                    )
                  )
                )

      , fuzz2 string int "oneOf consumes the first field if it is used" <|
        \field -> \value -> "{\"" ++ (escapeForJson field) ++ "\":" ++ (toString value) ++ "}"
          |> ( Decode.decodeString
               ( Decode.oneOf
                   [ (Decode.field field Decode.int)
                   , (Decode.succeed 0)
                   ]
                )
              )
          |> Expect.equal (Ok value)

      , fuzz string "oneOf does not consume a field if that path fails" <|
        \field ->
          "{\"" ++ (escapeForJson field) ++ "\":\"nonNumericValue\"}"
          |> ( Decode.decodeString
               ( Decode.oneOf
                   [ (Decode.field field Decode.int)
                   , (Decode.succeed 0)
                   ]
                )
              )
          |>  ( Expect.equal
                ( Err
                  ( Decode.Unused (Set.singleton [field]) )
                )
              )

      , fuzz2 string int "succeed reports no unused fields on non-objects" <|
        \field -> \value -> "{\"" ++ (escapeForJson field) ++ "\":" ++ (toString value) ++ "}"
          |> ( Decode.decodeString
               ( Decode.field field (Decode.succeed 0) )
              )
          |> Expect.equal (Ok 0)

      , fuzz string "fail passes out an error message (unused fields are irrelevant)" <|
        \error ->
          "{ \"field\":\"someValue\"" ++
          ", \"unused\":\"anotherValue\"" ++
          "}"
          |> ( Decode.decodeString
               ( Decode.field
                 "field"
                 (Decode.fail error)
               )
             )
          |> ( Expect.equal
               ( Err
                 ( Decode.InvalidJson
                    ("I ran into a `fail` decoder at _.field: " ++ error)
                 )
               )
             )
      ]

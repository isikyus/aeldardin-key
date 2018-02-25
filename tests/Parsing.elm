module Parsing exposing (all)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)

import Regex as R
import Parser.DecodeStrictly as Decode
import Set

import Dungeon as D
import Dungeon.ParseJson as ParseJson



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

all : Test
all =
    describe "Parsing dungeons"
      [ fuzz string "Parses an empty dungeon" <|
        \title -> "{\"title\":\"" ++ (escapeForJson title) ++ "\"}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal (Ok (D.Dungeon title []))

      , test "Fails on a dungeon with an invalid list of zones" <|
        \() -> "{\"title\":\"test\", \"zones\":[1,2,3]}"
          |> ParseJson.decodeDungeon
          -- TODO: should we be asserting a particular error message?
          -- Currently we convert all error messages to () and pass on any error.
          |> Result.mapError (\error -> ())
          |> Expect.equal (Err ())

      , fuzz3 string string int "Parses a dungeon with a named zone" <|
        \title -> \zone -> \key ->
          "{ \"title\":\"" ++ (escapeForJson title) ++ "\"" ++
          ", \"zones\":" ++
            "[{  \"id\":" ++ (toString key) ++
              ", \"name\":\"" ++ (escapeForJson zone) ++ "\"" ++
            "}]" ++
          "}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal
              ( Ok
                ( D.Dungeon title
                  [ D.Zone
                      (toString key)
                      (Just zone)
                      []
                      (D.Regions [])
                  ]
                )
              )

      , fuzz3 string string int "Parses a dungeon with a numerically-keyed room" <|
        \title -> \room -> \key ->
          "{ \"title\":\"" ++ (escapeForJson title) ++ "\"" ++
          ", \"zones\":" ++
            "[{  \"id\":1" ++
              ", \"rooms\": " ++
                "[{ \"key\": " ++ (toString key) ++
                ", \"name\": \"" ++ (escapeForJson room) ++ "\"" ++
                "}]" ++
            "}]" ++
          "}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal
              ( Ok
                ( D.Dungeon title
                  [ D.Zone
                      "1"
                      Nothing
                      [D.Room (toString key) room Nothing []]
                      (D.Regions [])
                  ]
                )
              )

      , fuzz2 string string "Reports an error on seeing an unknown field" <|
        \field -> \value ->
          "{ \"title\":\"someTitle\"" ++
          ", \"zones\":" ++
            "[{  \"id\":1" ++
              ", \"rooms\": " ++
                "[{ \"key\": 2" ++
                ", \"name\": \"someRoomName\"" ++
                -- Prefix with an underscore to ensure it doesn't use a real field name.
                ", \"_" ++ (escapeForJson field) ++ "\": \"" ++
                    (escapeForJson value) ++ "\"" ++
                "}]" ++
            "}]" ++
          "}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal
              ( Err
                  ( Decode.Unused
                    ( Set.singleton ["zones", "rooms", "_" ++ field] )
                  )
              )

      , fuzz2 string string "Reports all errors from unknown fields" <|
        \field -> \value ->
          "{ \"title\":\"someTitle\"" ++
          ", \"noSuchField\":\"someTitle\"" ++
          ", \"zones\":" ++
            "[{  \"id\":1" ++
              ", \"anotherUnusedField\":3" ++
              ", \"rooms\": " ++
                "[{ \"key\": 2" ++
                ", \"name\": \"someRoomName\"" ++
                -- Prefix with an underscore to ensure it doesn't use a real field name.
                ", \"_" ++ (escapeForJson field) ++ "\": \"" ++
                    (escapeForJson value) ++ "\"" ++
                "}]" ++
            "}]" ++
          "}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal
              ( Err
                  ( Decode.Unused
                    ( Set.fromList
                      [ ["noSuchField"]
                      , ["zones", "anotherUnusedField"]
                      , ["zones", "rooms", "_" ++ field]
                      ]
                    )
                  )
              )

      , fuzz3 string string string "Parses a dungeon with a string-keyed room" <|
        \title -> \room -> \key ->
          "{ \"title\":\"" ++ (escapeForJson title) ++ "\"" ++
          ", \"zones\":" ++
            "[{  \"id\":1" ++
              ", \"rooms\": " ++
              "[{ \"key\": \"" ++ (escapeForJson key) ++ "\"" ++
               ", \"name\": \"" ++ (escapeForJson room) ++ "\"" ++
              "}]" ++
            "}]" ++
          "}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal
              ( Ok
                ( D.Dungeon title
                  [ D.Zone
                      "1"
                      Nothing
                      [D.Room key room Nothing []]
                      (D.Regions [])
                  ]
                )
              )

      , fuzz4 string string string string "Parses a dungeon with a room exit with details" <|
        \title -> \room -> \key -> \details ->
          "{ \"title\":\"" ++ (escapeForJson title) ++ "\"" ++
          ", \"zones\":" ++
            "[{  \"id\":1" ++
              ", \"rooms\": " ++
              "[{ \"key\": \"" ++ (escapeForJson key) ++ "\"" ++
               ", \"name\": \"" ++ (escapeForJson room) ++ "\"" ++
                ", \"exits\":" ++
                    "[{ \"to\":\"" ++ (escapeForJson key) ++ "\"" ++
                      ", \"type\":\"concealed\"" ++
                      -- TODO: signs of exits not supported yet.
                      -- ", \"signs\":\"" ++ (escapeForJson details) ++ "\"" ++
                    "}]" ++
              "}]" ++
            "}]" ++
          "}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal
              ( Ok
                ( D.Dungeon title
                  [ D.Zone
                      "1"
                      Nothing
                      [ D.Room
                          key
                          room
                          Nothing
                          [ D.Connection "concealed" key ]
                      ]
                      (D.Regions [])
                  ]
                )
              )

      , fuzz5 string string string int string "Parses a dungeon with multiple linked rooms" <|
        \title -> \key1 -> \room1 -> \key2 -> \room2 ->
          "{ \"title\":\"" ++ (escapeForJson title) ++ "\"" ++
          ", \"zones\":" ++
            "[{  \"id\":1" ++
              ", \"rooms\": " ++
              "[ { \"key\": \"" ++ (escapeForJson key1) ++ "\"" ++
                ", \"name\": \"" ++ (escapeForJson room1) ++ "\"" ++
                ", \"exits\":" ++
                    "[ " ++ (toString key2) ++
                    ", {\"to\":" ++ (toString key2) ++ "}" ++
                    "]" ++
                "}" ++
              ", { \"key\": " ++ (toString key2) ++
                ", \"name\": \"" ++ (escapeForJson room2) ++ "\"" ++
                ", \"exits\":" ++
                    "[ \"" ++ (escapeForJson key1) ++ "\"" ++
                    ", {\"to\":\"" ++ (escapeForJson key1) ++ "\"" ++
                      ", \"type\":\"concealed\"" ++
                      "}" ++
                    "]" ++
                "}" ++
              "]" ++
            "}]" ++
          "}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal
              ( Ok
                ( D.Dungeon title
                  [ D.Zone
                      "1"
                      Nothing
                      [ D.Room
                          key1
                          room1
                          Nothing
                          [ D.Connection "door" (toString key2)
                          , D.Connection "door" (toString key2)
                          ]
                      , D.Room
                          (toString key2)
                          room2
                          Nothing
                          [ D.Connection "door" key1
                          , D.Connection "concealed" key1
                          ]
                      ]
                      (D.Regions [])
                  ]
                )
              )

      , fuzz3 string string int "Parses a dungeon with a room within a region" <|
        \title -> \room -> \key ->
          "{ \"title\":\"" ++ (escapeForJson title) ++ "\"" ++
          ", \"zones\":" ++
            "[{  \"id\":1" ++
              ", \"regions\": " ++
              "[{  \"id\":2" ++
                ", \"rooms\": " ++
                  "[{ \"key\": \"" ++ (toString key) ++ "\"" ++
                  ", \"name\": \"" ++ (escapeForJson room) ++ "\"" ++
                  "}]" ++
              "}]" ++
            "}]" ++
          "}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal
              ( Ok
                ( D.Dungeon title
                  [ D.Zone
                      "1"
                      Nothing
                      []
                      ( D.Regions
                        [ D.Zone
                          "2"
                          Nothing
                          [ D.Room (toString key) room Nothing []
                          ]
                          (D.Regions [])
                        ]
                      )
                  ]
                )
              )

      , fuzz2 string string "Parses a dungeon with a room description" <|
        \room -> \description ->
          "{ \"title\":\"Test Dungeon\"" ++
          ", \"zones\":" ++
            "[{  \"id\":1" ++
            ", \"rooms\": " ++
              "[{ \"key\": \"testKey\"" ++
              ", \"name\": \"" ++ (escapeForJson room) ++ "\"" ++
              ", \"description\": \"" ++ (escapeForJson description) ++ "\"" ++
              "}]" ++
            "}]" ++
          "}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal
              ( Ok
                ( D.Dungeon "Test Dungeon"
                  [ D.Zone
                      "1"
                      Nothing
                      [ D.Room
                          "testKey"
                          room
                          (Just description)
                          []
                      ]
                      (D.Regions [])
                  ]
                )
              )
      ]

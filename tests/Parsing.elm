module Parsing exposing (all)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)

import Regex as R

import Dungeon as D
import Dungeon.ParseJson as ParseJson

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

      , fuzz3 string string int "Parses a dungeon with only empty zones" <|
        \title -> \room -> \key ->
          "{ \"title\":\"" ++ (escapeForJson title) ++ "\"" ++
          ", \"zones\":" ++
            "[{}]" ++
          "}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal
              ( Ok
                ( D.Dungeon title
                  [ D.Zone
                      []
                      (D.Regions [])
                  ]
                )
              )

      , fuzz3 string string int "Parses a dungeon with a room" <|
        \title -> \room -> \key ->
          "{ \"title\":\"" ++ (escapeForJson title) ++ "\"" ++
          ", \"zones\":" ++
            "[{ \"rooms\": " ++
              "[{ \"key\": \"" ++ (toString key) ++ "\"" ++
               ", \"name\": \"" ++ (escapeForJson room) ++ "\"" ++
              "}]" ++
            "}]" ++
          "}"
          |> \dungeonJson -> ParseJson.decodeDungeon dungeonJson
          |> Expect.equal
              ( Ok
                ( D.Dungeon title
                  [ D.Zone
                      [D.Room (toString key) room []]
                      (D.Regions [])
                  ]
                )
              )

      , fuzz3 string string int "Parses a dungeon with a room within a region" <|
        \title -> \room -> \key ->
          "{ \"title\":\"" ++ (escapeForJson title) ++ "\"" ++
          ", \"zones\":" ++
            "[{ \"regions\": " ++
              "[{ \"rooms\": " ++
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
                      []
                      ( D.Regions
                        [ D.Zone
                          [ D.Room (toString key) room []
                          ]
                          (D.Regions [])
                        ]
                      )
                  ]
                )
              )
      ]
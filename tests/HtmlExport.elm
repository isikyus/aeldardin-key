module HtmlExport exposing (all)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, tuple, string)
import Test exposing (..)
import String

import Dungeon as D
import Export.Html

expectOkAnd : (x -> Expect.Expectation) -> Result String x -> Expect.Expectation
expectOkAnd expectation result =
  case result of
       Ok x ->
         expectation x

       Err message ->
         Expect.fail message


expectSubstring : String -> String -> Expect.Expectation
expectSubstring needle haystack =
  Expect.true
    ( "Expected \""
        ++ haystack
        ++ "\" to contain \""
        ++ needle
        ++ "\"." )
    (String.contains needle haystack)


all : Test
all =
  describe "HTML export"
    [ fuzz3 Fuzz.string Fuzz.string Fuzz.string "Includes dungeon, zone, and room titles" <|
        \dungeon -> \zone -> \room ->
          D.Dungeon
            dungeon
            [ D.Zone
                "z1"
                (Just zone)
                [ D.Room
                    "r1"
                    room
                    []
                ]
                ( D.Regions [] )
            ]
          |> Export.Html.toHtmlText
          |> expectOkAnd
              ( Expect.all

                  -- Assume tags are opened correctly by Elm's HTML generation
                  [ expectSubstring (dungeon ++ "</h1>")
                  , expectSubstring (zone ++ "</h2>")
                  , expectSubstring (room ++ "</h3>")
                 ]
              )
    , fuzz Fuzz.string "Includes zones recursively" <|
        \childZone ->
          D.Dungeon
            "<dungeon name>"
            [ D.Zone
                "z1"
                Nothing
                []
                ( D.Regions
                    [ D.Zone
                        "z2"
                        (Just childZone)
                        []
                        (D.Regions [])
                    ]
                )
            ]
          |> Export.Html.toHtmlText
          |> expectOkAnd
              ( expectSubstring
                  (childZone ++ "</h3>")
              )
    ]

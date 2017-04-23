module HtmlExport exposing (all)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
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
    [ fuzz3 string string string "Includes dungeon, zone, and room titles" <|
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
                   [ expectSubstring (dungeon ++ "</h1>")
                   , expectSubstring (zone ++ "</h2>")
                   , expectSubstring (room ++ "</h3>")
                  ]
               )
    ]

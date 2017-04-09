module Export.Html exposing (toHtmlText, toHtml)

import Dungeon exposing (..)

import HtmlToString exposing (htmlToString)
import Html

toHtmlText : Dungeon -> String
toHtmlText dungeon =
  htmlToString (toHtml dungeon)

toHtml : Dungeon -> Html.Html msg
toHtml dungeon =
  Html.h1 [] [ Html.text (dungeon.title ++ "a") ]

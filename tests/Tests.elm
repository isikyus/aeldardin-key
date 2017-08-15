module Tests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String

import HtmlExport
import GraphvizExport
import GraphvizParser
import StrictDecoding
import Parsing

all : Test
all =
  describe "aeldardin"
    [ HtmlExport.all
    , GraphvizExport.all
    , GraphvizParser.tests
    , StrictDecoding.all
    , Parsing.all
    ]

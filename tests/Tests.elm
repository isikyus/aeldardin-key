module Tests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, tuple, string)
import Test exposing (..)
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

module Tests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String

import GraphvizExport
import GraphvizParser
import Parsing

all : Test
all =
  describe "aeldardin"
    [ GraphvizExport.all
    , GraphvizParser.tests
    , Parsing.all
    ]

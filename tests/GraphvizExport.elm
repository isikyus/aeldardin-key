module GraphvizExport exposing (all)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String

-- Parsing library -- P for Parse
import Combine as P exposing(..)

import Dungeon as D
import Export.Graphviz

-- Dungeon fuzzer definition -- TODO: extract this to its own file.
roomWithNameAndExits : String -> List String -> D.Room
roomWithNameAndExits name exits =
  D.Room
    -- Use name as key too -- one is supposed to be human-readable,
    -- the other succinct, but we don't care about either for this test.
    name
    name
    ( List.map
      (\exit -> D.Connection "door" exit)
      exits
    )

-- Creates a dungeon with a room using each given name,
-- which is "fully connected" -- every room connects to every other.
dungeonWithRoomsNamed : List String -> D.Dungeon
dungeonWithRoomsNamed names =
  D.Dungeon
    "Test Dungeon with rooms for names"
    [ D.Zone
      ( List.map
        (\name -> roomWithNameAndExits name names)
        names
      )
      (D.Regions [])
    ]

dungeon : Fuzz.Fuzzer D.Dungeon
dungeon =
  Fuzz.map
    dungeonWithRoomsNamed
    (Fuzz.list Fuzz.string)


-- Parser for a subset of the Graphviz file format.
-- (see http://www.graphviz.org/content/dot-language)
-- Only handles undirected graphs defined using only edges.
type alias Edge = (String, String)

type alias Graph =
  { title : String,
    edges : List Edge
  }

-- Parse a graph, defined as:
--
--   graph : [ "strict" ] ( "graph" | "digraph" ) [ ID ] "{" stmt_list "}"
--
-- I'm simplifying the definition to:
--
--  graph : "graph" ID "{" stmt_list "}"
--
graph : P.Parser () Graph
graph =
  P.skip (P.string "graph")
    *> P.whitespace
    *> idString
    |> P.map Graph
    |> P.andMap
      ( P.whitespace
        *> ( P.braces statementList)
        <* P.whitespace
        <* P.end
      )

-- stmt_list, defined as
--
--   stmt: [ stmt [";"] stmt_list ]
--
-- I.E. either empty, or a statement, possible semicolon,
-- and following (possibly empty) statement list.
statementList : P.Parser () (List Edge)
statementList =
  P.whitespace
    *>
      ( ( P.sepEndBy
          (P.whitespace *> P.maybe (P.string ";") <* P.whitespace)
          statement
        )
        |> P.mapError ( (++) ["Expected a semicolon-separated list of statements"] )
      )
    <* P.whitespace

-- stmt, defined as:
--
--   stmt : node_stmt | edge_stmt | attr_stmt | ID "=" ID | subgraph
--
-- I only care about edge statements for the moment, which have their own definition:
--
--   edge_stmt : (node_id | subgraph) edgeRHS [attr_list]
--   node_id : ID [ port ]
--   edgeRHS : edgeop (node_id | subgraph) edgeRHS
--
-- I don't care about ports, subgraphs, attributes,
-- or multiple edges in one statement,
-- so this simplifies to:
--
--   edge_stmt : ID edgeop ID
--
-- And since I'm assuming undirected graphs, edgeop should always be "--"
statement : P.Parser () Edge
statement =
  idString
    <* P.whitespace
    <* P.string "--"
    <* P.whitespace

    -- (,) is the constructor for two-tuples, such as Edge
    |> P.map (,)
    |> P.andMap idString
    |> P.mapError ( (++) ["Expected a statement, like \"node -- node2\""] )

-- Parse a GraphViz ID
-- They define four kinds of ID: alphanumeric, numbers, quoted, and HTML.
--
-- I only accept the two:
--  * alphanumerics and  _, not starting with a digit, and
--  * numbers (ignoring negative numbers and fractions for the moment)
idString : P.Parser () String
idString =
  P.choice
  [ -- Alphanumerics, including \200-\377,
    -- which are presumably valid in the code page Graphviz uses.
    -- Can't start with a digit.
    P.regex "[A-Za-z\200-\377_][0-9A-Za-z\200-\377_]*"

    -- Numbers
  , P.regex "[0-9]+"
  , P.string "a"
  , P.string "b"
  ]


-- Custom expectations
-- TODO: how do I shorten a really long type annotation? Should I be importing aliases?
expectParseOk : (value -> Expect.Expectation) -> Result (state, P.InputStream, List String) (state, stream, value) -> Expect.Expectation
expectParseOk expectedOutput result =
  case result of
    Ok (_, stream, result) ->
      expectedOutput result

    Err (_, stream, errors) ->
      Expect.fail
        ( "Expected parse success, got failures at '"
          ++ stream.input
          ++ "': "
          ++ (String.join ", " errors)
        )

expectParseErr : Result err value -> Expect.Expectation
expectParseErr result =
  case result of
    Err _ ->
      Expect.pass

    Ok _ ->
      Expect.fail ("Expected parse to fail, but it succeded")

expectValidGraphviz : String -> Expect.Expectation
expectValidGraphviz graphvizOutput =
  P.parse graph graphvizOutput
    |> expectParseOk (\_ -> Expect.pass)

all : Test
all =
  describe "Sample Test Suite"
    [ describe "Graphviz parser"
      [ test "Parsing an empty graph" <|
        \() ->
          P.parse graph "graph title {}"
            |> expectParseOk
                (\result -> Expect.equal 
                  result
                  (Graph "title" [])
                )

      , test "Parsing a graph with edges" <|
        \() ->
        P.parse graph "graph title { a -- b; b -- a }"
            |> expectParseOk
                (\result -> Expect.equal 
                  result
                  ( Graph
                    "title"
                    [ ("a", "b")
                    , ("b", "a")
                    ]
                  )
                )

      , test "Parsing an empty graph with an invalid title" <|
        \() -> P.parse graph "graph a title {}"
          |> expectParseErr

      , test "Parsing a graph with invalid node names" <|
        \() -> P.parse graph "graph title { can -- can't; can't -- can }"
          |> expectParseErr
      ]
    , describe "Graphviz export"

      []
      -- Un-quoted Graphviz identifiers are limited to alphanumerics + _,
      -- and either start with a non-numeral (like C identifiers)
      -- or consist only of numerals.
      -- TODO: avoid all this by using _quoted_ identifiers instead.
  --    [ fuzz dungeon "Node names only contain 'identifier' characters" <|
  --        \d -> Export.Graphviz.toGraphviz d
  --          |> expectValidGraphviz

--         , describe "Unit test examples"
--             [ test "Addition" <|
--                 \() ->
--                     Expect.equal (3 + 7) 10
--             , test "String.left" <|
--                 \() ->
--                     Expect.equal "a" (String.left 1 "abcdefg")
--             , test "This test should fail - you should remove it" <|
--                 \() ->
--                     Expect.fail "Failed as expected!"
--             ]
--         , describe "Fuzz test examples, using randomly generated input"
--             [ fuzz (list int) "Lists always have positive length" <|
--                 \aList ->
--                     List.length aList |> Expect.atLeast 0
--             , fuzz (list int) "Sorting a list does not change its length" <|
--                 \aList ->
--                     List.sort aList |> List.length |> Expect.equal (List.length aList)
--             , fuzzWith { runs = 1000 } int "List.member will find an integer in a list containing it" <|
--                 \i ->
--                     List.member i [ i ] |> Expect.true "If you see this, List.member returned False!"
--             , fuzz2 string string "The length of a string equals the sum of its substrings' lengths" <|
--                 \s1 s2 ->
--                     s1 ++ s2 |> String.length |> Expect.equal (String.length s1 + String.length s2)
--             ]
  --      ]
    ]

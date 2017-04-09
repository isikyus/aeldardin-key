port module Aeldardin exposing (main)

-- Very roughly based on https://gist.github.com/evancz/e69723b23958e69b63d5b5502b0edf90
-- and https://github.com/ElmCast/elm-node/blob/master/example/Example.elm

-- Needed to define port modules -- but apparently it's enough to require Dungeon.ParseJson, which itself depends on this.
-- import Json.Decode

-- Imports to set up program
-- TODO: not sure if all of these are used.
import Platform
import Platform.Cmd as Cmd
import Platform.Sub as Sub

-- Load Aeldardin libraries.
import Dungeon.ParseJson
import Export.Graphviz
import Export.Html

main : Program Never Model Msg
main =
    Platform.program
        { init =
          ( EmptyModel,
            Cmd.none
          )
        , update = update
        , subscriptions = subscriptions
        }

-- MODEL

-- Not actually used, as we don't need any internal state.
type Model = EmptyModel

-- UPDATE

type Msg
  = Done
  | ToGraphviz (String)
  | ToHtml (String)

port done : String -> Cmd msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ToGraphviz jsonString ->
      case Dungeon.ParseJson.decodeDungeon jsonString of
        Ok dungeon ->
          ( model, done ( Export.Graphviz.toGraphviz dungeon ) )

        -- TODO: return errors using their own port.
        Err message ->
          ( model, done message )

    ToHtml jsonString ->
      case Dungeon.ParseJson.decodeDungeon jsonString of
        Ok dungeon ->
          ( model, done ( Export.Html.toHtmlText dungeon ) )

        -- TODO: return errors using their own port.
        Err message ->
          ( model, done message )

    Done ->
      ( model, Cmd.none )

-- SUBSCRIPTIONS

port toGraphviz : (String -> msg) -> Sub msg
port toHtml : (String -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ toGraphviz ToGraphviz
    , toHtml ToHtml
    ]

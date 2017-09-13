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
import Parser.DecodeStrictly as DecodeStrictly
import Dungeon
import Dungeon.ParseJson
import Export.Graphviz
import Export.Html
import Set

main : Program Never Model Msg
main =
    Platform.program
        { init =
          ( Nothing,
            Cmd.none
          )
        , update = update
        , subscriptions = subscriptions
        }

-- MODEL

type alias Model = Maybe Dungeon.Dungeon

-- UPDATE

type Msg
  = Done
    | Load (String)
    | ToGraphviz ()
    | ToHtml ()

port done : String -> Cmd msg
port warn : String -> Cmd msg
port error : String -> Cmd msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Load jsonString ->
      case Dungeon.ParseJson.decodeWithUnusedFields jsonString of
        Ok (dungeon, unusedFields) ->
          ( Just dungeon
          , if (Set.size unusedFields == 0) then
              Cmd.none
            else
              Cmd.batch
                ( List.map
                    warn
                    (DecodeStrictly.unusedFieldWarnings unusedFields)
                )
          )

        -- TODO: return errors using their own port.
        Err message ->
          ( Nothing, error message )

    ToGraphviz () ->
        case model of
          Just dungeon ->
            ( model, done ( Export.Graphviz.toGraphviz dungeon ) )

          Nothing ->
            ( model, error "No dungeon to export" )

    ToHtml () ->
        case model of
          Just dungeon ->
            case (Export.Html.toHtmlText dungeon) of
              Ok html ->
                ( model, done html )

              -- TODO: return errors using their own port.
              Err message ->
                ( model, error message )

          Nothing ->
            ( model, error "No dungeon to export" )

    Done ->
      ( model, Cmd.none )

-- SUBSCRIPTIONS

port load : (String -> msg) -> Sub msg
port toGraphviz : (() -> msg) -> Sub msg
port toHtml : (() -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ load Load
    , toGraphviz ToGraphviz
    , toHtml ToHtml
    ]

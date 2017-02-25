port module Aeldardin exposing (main)

-- Very roughly based on https://gist.github.com/evancz/e69723b23958e69b63d5b5502b0edf90
-- and https://github.com/ElmCast/elm-node/blob/master/example/Example.elm

-- Needed to define port modules, apparently.
import Json.Decode

-- Imports to set up program
-- TODO: not sure if all of these are used.
import Platform
import Platform.Cmd as Cmd
import Platform.Sub as Sub
import Task

-- Load Aeldardin libraries.
import Dungeon exposing (Dungeon)
import Dungeon.ParseJson

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
  | ToDot (String)

port done : String -> Cmd msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ToDot jsonString ->
      case Dungeon.ParseJson.decodeDungeon jsonString of
        Ok dungeon ->
          ( model, done ( dungeonToDot dungeon ) )

        -- TODO: return errors using their own port.
        Err message ->
          ( model, done message )

    Done ->
      ( model, Cmd.none )

-- SUBSCRIPTIONS

port toDot : (String -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
  toDot ToDot


-- TODO: functions to be moved to other files.

-- CONVERSION TO ToDot

dungeonToDot : Dungeon -> String
dungeonToDot dungeon =
  "graph " ++ dungeon.title ++ " { }"
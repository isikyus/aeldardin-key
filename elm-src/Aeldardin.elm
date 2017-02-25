port module Aeldardin exposing (main)

-- Very roughly based on https://gist.github.com/evancz/e69723b23958e69b63d5b5502b0edf90
-- and https://github.com/ElmCast/elm-node/blob/master/example/Example.elm

import Platform
import Platform.Cmd as Cmd
import Platform.Sub as Sub
import Task

-- Needed to define port modules, apparently.
import Json.Decode


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
      case Json.Decode.decodeString dungeonDecoder jsonString of
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

-- DUNGEON TYPES

type alias Dungeon =
  { title : String
  }

dungeonDecoder = Json.Decode.map Dungeon ( Json.Decode.field "title" Json.Decode.string )

-- CONVERSION TO ToDot

dungeonToDot : Dungeon -> String
dungeonToDot dungeon =
  "graph " ++ dungeon.title ++ " { }"
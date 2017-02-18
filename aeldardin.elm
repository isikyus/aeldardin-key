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
      ( model, done (jsonString ++ "a") )

    Done ->
      ( model, Cmd.none )

-- SUBSCRIPTIONS

port toDot : (String -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
  toDot ToDot

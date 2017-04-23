module Export.Html exposing (toHtmlText, toHtml)

import Dungeon exposing (..)

import HtmlToString exposing (htmlToString)
import Html
import Html.Attributes

toHtmlText : Dungeon -> Result String String
toHtmlText dungeon =
  Result.map
    htmlToString
    (toHtml dungeon)

-- Unwrap all Results in a list if they all succeeded,
-- or return a list of the errors if any failed.
allOrErrors : List (Result x a) -> Result (List x) (List a)
allOrErrors attempts =
  List.foldl
    ( \attempt -> \resultsSoFar ->
        case resultsSoFar of
              Ok list ->
                case attempt of
                    Ok value ->
                      Ok (value :: list)

                    Err error ->
                      Err [error]

              Err errors ->
                case attempt of
                      Ok value ->
                        Err errors

                      Err error ->
                        Err (error :: errors)
    )
    ( Ok [] )
    attempts

toHtml : Dungeon -> Result String (Html.Html msg)
toHtml dungeon =
  Result.map
    ( \zoneHtmlTags ->
        ( Html.section
          []
          ( [ Html.h1 [] [ Html.text dungeon.title ] ]
            ++ ( zoneHtmlTags )
          )
        )
    )
    ( htmlForZones 2 dungeon.zones )

htmlForZones : Int -> List Zone -> Result String (List (Html.Html msg))
htmlForZones depth zones =
    ( allOrErrors
      ( List.map (zoneToHtml depth) zones )
    )
    |> Result.mapError (List.foldl String.append "")

zoneToHtml : Int -> Zone -> Result String (Html.Html msg)
zoneToHtml nesting zone =
  Result.map3
    ( \heading -> \roomHtml -> \zoneHtml ->
        ( Html.section
            [ Html.Attributes.id ("zone-" ++ zone.key) ]
            ( [ heading
                  []
                  [ Html.text
                    ( Maybe.withDefault
                      ("Zone " ++ toString zone.key)
                      zone.name
                    )
                  ]
              ]
              ++ roomHtml ++ zoneHtml
            )
        )
    )
    ( headingForDepth nesting )
    ( htmlForRooms (nesting + 1) zone.rooms )
    ( htmlForZones
        (nesting + 1)
        (Dungeon.regionZones zone.regions)
    )

htmlForRooms : Int -> List Room -> Result String (List (Html.Html msg))
htmlForRooms depth rooms =
    ( allOrErrors
      ( List.map (roomToHtml depth) rooms )
    )
    |> Result.mapError (List.foldl String.append "")

roomToHtml : Int -> Room -> Result String (Html.Html msg)
roomToHtml nesting room =
  Result.map
    ( \heading ->
        ( Html.section
            [ Html.Attributes.id ("room-" ++ room.key) ]
            ( [ heading
                  []
                  [ Html.text
                      room.name
                  ]
              ]
            )
        )
    )
    ( headingForDepth nesting )

-- Figures out the correct type of heading for a given level of nesting.
headingForDepth : Int -> Result String (List (Html.Attribute msg) -> List (Html.Html msg) -> Html.Html msg)
headingForDepth depth =
  case depth of
       1 ->
        Ok Html.h1

       2 ->
        Ok Html.h2

       3 ->
        Ok Html.h3

       4 ->
        Ok Html.h4

       5 ->
        Ok Html.h5

       6 ->
        Ok Html.h6

       _ ->
        if depth < 0 then
          Err "Cannot create a heading with negative depth"
        else
          Err "Cannot create more than six levels of nested headings"

module Parser.DecodeStrictly exposing (Decoder, Failure(..), decodeString, string, bool, int, float, field)
-- map, map2, map3, field)

-- Wraps the standard Json.Decode, adding the ability to fail
-- if the decoded JSON contains any unrecognised elements.

import Dict
import Set exposing (Set)
import Json.Decode as Decode

-- The fields we've seen so far that haven't been used.
-- Stored as a set of lists of keys, so that looking up
-- that sequence of keys will find the field that was unused.
type alias UnusedFields = Set.Set (List String)

-- A decode state consists of:
-- (a) what we've decoded so far, and
-- (b) a list of unused fields.
type DecodeState a = Decoding a UnusedFields

-- Our decoders are the same as Json.Decode's,
-- except that they return a DecodeState
type alias Decoder a = Decode.Decoder (DecodeState a)

-- Our errors may be either a set of unused fields,
-- or a string error from the underlying decoder.
type Failure = Unused UnusedFields | InvalidJSON String

-- Actually allow ourselves to decode stuff
-- TODO: may want a way to decode and return warnings
decodeString : Decoder a -> String -> Result Failure a
decodeString decoder string =
  let
      result = Decode.decodeString decoder string
  in
    case result of
        Ok (Decoding data unusedFields) ->
          if (Set.isEmpty unusedFields) then
            Ok data
          else
            Err (Unused unusedFields)

        Err message ->
          Err (InvalidJSON message)


-- Copy primitive decoders

-- Helper function for copying decoders
addUnusedFields : UnusedFields -> Decode.Decoder a -> Decoder a
addUnusedFields unusedFields decoder =
  Decode.map
    ( \decoded -> Decoding decoded unusedFields )
    decoder

string : Decoder String
string =
  addUnusedFields Set.empty Decode.string

bool : Decoder Bool
bool =
  Decode.map
    ( \decodedBool -> Decoding decodedBool Set.empty )
    ( Decode.bool )

int : Decoder Int
int =
  Decode.map
    ( \decodedInt -> Decoding decodedInt Set.empty )
    ( Decode.int )

float : Decoder Float
float =
  Decode.map
    ( \decodedFloat -> Decoding decodedFloat Set.empty )
    ( Decode.float )

-- Create a new decoder with a modified list of unused fields.
-- mapUnusedFields : ((Set String) -> (Set String)) -> Decoder a -> Decoder a
-- mapUnusedFields function decoder =
--   Decode.map
--     ( \(Decoding value unusedFields) ->
--         Decoding
--           value
--           (function unusedFields)
--     )
--     decoder
-- 
-- -- Add a prefix to all unused fields in a DecodeState
-- prefixUnusedFields : String -> DecodeState a -> DecodeState a
-- prefixUnusedFields prefix (Decoding value unusedFields)=
--   Decoding
--     value
--     (Set.map (String.append prefix) unusedFields)

-- Decode an object to its keys (represented as an UnusedFields object)
fieldNames : Decode.Decoder UnusedFields
fieldNames =
  Decode.map
    ( \pairs ->
      ( Set.fromList
        ( List.map
          (\(key, _) -> [key])
          pairs
        )
      )
    )
    (Decode.keyValuePairs Decode.value)

-- Decode a field, and mark all other fields of the current object as unused.
field : String -> Decoder a -> Decoder a
field name decoder =
  Decode.map2
    ( \(Decoding value warnings) -> \fields ->
        -- TODO: need to carry over any warnings from the inner decoder.
        ( Decoding
          value
          (Set.remove [name] fields)
        )
    )
    ( Decode.field name decoder )
    fieldNames

--   Decode.andThen
--     ( \(Decoding dict warnings) ->
--         ( Maybe.withDefault
--             -- TODO: improve error messages
--             ( Decode.fail ("Field " ++ name ++ " not found.") )
--             ( Decode.succeed
--                 ( Decoding
--                     (Dict.get name)
-- 
--                     ( Set.union
--                         -- Remove the field we've just used from the unused-fields list.
--                         ( Dict.keys dict
--                           |> Set.fromList
--                           |> Set.filter (\a -> a /= name)
--                         )
--                         -- Keep all warnings from the inner decoder
--                         ( Set.map (String.append name) warnings )
--                     )
--                 )
--             )
--         )
--     )
--     (Decode.dict Decode.value)

-- Analoguous to Json.Decode.map
-- Preserves unused fields as-is.
-- map : (a -> value) -> Decoder a -> Decoder value
-- map function decoder =
--   let
--       wrappedFunction : DecodeState a -> DecodeState value
--       wrappedFunction (Decoding data warnings) =
--         Decoding (function data) warnings
--   in
--     Decode.map
--       wrappedFunction
--       decoder

-- Analogous to Json.Decode.andThen
-- Keeps only unused field values not used by _either_ decoder.
-- andThen : (a -> Decoder b) -> Decoder a -> Decoder b
-- andThen generator decoder =
--   Decode.andThen
--     (\(Decoding data warnings) ->
--       ( generator data
--         |> mapUnusedFields (Set.intersect warnings)
--       )
--     )
--     decoder

-- Re-implementations of Json.Decode.mapN functions
-- map2 : (a -> b -> value) -> Decoder a -> Decoder b -> Decoder value
-- map2 builder aDecoder bDecoder =
  

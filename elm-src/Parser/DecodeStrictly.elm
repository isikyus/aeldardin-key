module Parser.DecodeStrictly exposing (Decoder, Failure(..), unusedFieldWarnings, decodeString, string, bool, int, float, field, optionalField, list, lazy, map, map2, map3, map4, oneOf, succeed, fail)

-- Wraps the standard Json.Decode, adding the ability to fail
-- if the decoded JSON contains any unrecognised elements.

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
type Failure = Unused UnusedFields | InvalidJson String


-- Warnings helper -- like Ruby's Array#join
join : String -> List String -> String
join separator list =
  List.intersperse separator list
    |> List.foldr (++) ""

-- Build a warning message about unused fields.
-- TODO: should I have this sort of UI code here?

unusedFieldWarnings : UnusedFields -> String
unusedFieldWarnings unused =
  ( Set.map
      ( \fieldPath ->
        "Warning: unused field " ++
        ( join "." fieldPath )
      )
      unused
  )
    |> Set.toList |> join "\n"


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
          Err (InvalidJson message)



-- Helper functions for wrapping decoders

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

-- Nested-object-decoding helper
-- Pushes a string onto all unused-field lists in an UnusedFields object.
prefixUnusedFields : String -> UnusedFields -> UnusedFields
prefixUnusedFields prefix fields =
  Set.map
    ( \unprefixed -> prefix :: unprefixed )
    fields

-- Build a DecodeStrictly.Decoder from two Json.Decode.Decoders:
-- one for the actual value, and one for the unused fields.
addUnusedFields : Decode.Decoder a -> Decode.Decoder UnusedFields -> Decoder a
addUnusedFields decoder unusedFieldsDecoder =
  Decode.map2
    Decoding
    decoder
    unusedFieldsDecoder

-- Copy primitive decoders

noUnusedFields : Decode.Decoder UnusedFields
noUnusedFields =
  Decode.succeed Set.empty

string : Decoder String
string =
  addUnusedFields Decode.string noUnusedFields

bool : Decoder Bool
bool =
  addUnusedFields Decode.bool noUnusedFields
--
int : Decoder Int
int =
  addUnusedFields Decode.int noUnusedFields

float : Decoder Float
float =
  addUnusedFields Decode.float noUnusedFields

-- Data structure decoders

list : Decoder a -> Decoder (List a)
list decoder =
  Decode.map
    ( \list ->
      ( Decoding
          ( List.map
              (\(Decoding value _) -> value)
              list
          )
          ( List.foldr
              Set.union
              Set.empty
              ( List.map
                  (\(Decoding _ warnings) -> warnings)
                  list
              )
          )
      )
    )
    ( Decode.list decoder )

lazy : (() -> Decoder a) -> Decoder a
lazy decoderBuilder =
  Decode.lazy decoderBuilder

--Primitive object decoders

-- Decode a field, and mark all other fields of the current object as unused.
field : String -> Decoder a -> Decoder a
field name decoder =
  Decode.map2
    ( \(Decoding value warnings) -> \fields ->
        -- TODO: need to carry over any warnings from the inner decoder.
        ( Decoding
          value
          ( (Set.remove [name] fields)
            |> ( Set.union (prefixUnusedFields name warnings) )
          )
        )
    )
    ( Decode.field name decoder )
    fieldNames

-- As above, but decodes to a Maybe, returning Nothing if field not found
-- instead of a string error message.
-- A more robust replacement for maybe (which silently swallows parsing
-- errors in the decoder it wraps)
optionalField : String -> Decoder a -> Decoder (Maybe a)
optionalField name decoder =
  Decode.andThen
    ( \fields ->
      if (Set.member [name] fields) then
        -- Use the given decoder, but wrap the result in Just.
        map
          Just
          (field name decoder)
      else
        Decode.succeed (Decoding Nothing fields)
    )
    fieldNames

-- Re-implementations of Json.Decode.map* functions

map : (a -> value) -> Decoder a -> Decoder value
map builder decoder =
  Decode.map
    ( \(Decoding aValue unused) -> Decoding (builder aValue) unused )
    decoder

map2 : (a -> b -> value) -> Decoder a -> Decoder b -> Decoder value
map2 builder decoder1 decoder2 =
  Decode.map2
    ( \(Decoding value1 unused1) -> \(Decoding value2 unused2) ->
      ( Decoding
        (builder value1 value2)

        -- Fields are unused if we didn't use them for either component.
        (Set.intersect unused1 unused2)
      )
    )
    decoder1
    decoder2

map3 : (a -> b -> c -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder value
map3 builder decoder1 decoder2 decoder3 =
  Decode.map3
    ( \(Decoding value1 unused1) ->
      \(Decoding value2 unused2) ->
      \(Decoding value3 unused3) ->
      ( Decoding
        (builder value1 value2 value3)

        -- Fields are unused if we didn't use them for either component.
        (Set.intersect unused1 (Set.intersect unused2 unused3) )
      )
    )
    decoder1
    decoder2
    decoder3

map4 : (a -> b -> c -> d -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder value
map4 builder decoder1 decoder2 decoder3 decoder4 =
  Decode.map4
    ( \(Decoding value1 unused1) ->
      \(Decoding value2 unused2) ->
      \(Decoding value3 unused3) ->
      \(Decoding value4 unused4) ->
      ( Decoding
        (builder value1 value2 value3 value4)

        -- Fields are unused if we didn't use them for either component.
        (Set.intersect
          ( Set.intersect unused1 unused2 )
          ( Set.intersect unused3 unused4)
        )
      )
    )
    decoder1
    decoder2
    decoder3
    decoder4

-- Decoders for inconsistent structure

oneOf : List (Decoder a) -> Decoder a
oneOf decoders =
    ( Decode.oneOf decoders )

-- "Fancy" decoders

succeed : a -> Decoder a
succeed value =
  addUnusedFields
    ( Decode.succeed value )

    -- Look for unused fields only if we're actually decoding an object.
    ( Decode.map
        ( Maybe.withDefault Set.empty )
        ( Decode.maybe fieldNames )
    )

fail : String -> Decoder a
fail error =
  addUnusedFields
    ( Decode.fail error )
    noUnusedFields

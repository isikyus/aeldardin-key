module Dungeon exposing (Dungeon, Room, Zone, Regions(..), Connection, rooms, localRooms, findRoom)

-- Types representing an Aeldardin dungeon.
-- These may eventually need to be parametric or something to allow addons with their own types.

type alias Dungeon =
  { title : String
  , zones : List Zone
  }

type alias Zone =
  { key : String
  , name: Maybe String
  , rooms : List Room
  , regions : Regions
  }

type Regions =
  Regions (List Zone)

type alias Room =
  { key : String
  , name: String
  , exits: List Connection
  }

type alias Connection =
  { doorType : String
  , destination : String
  }

-- Dungeon operations

-- Get all rooms of the dungeon, as a single array.
rooms : Dungeon -> List Room
rooms dungeon =
  List.concatMap localRooms dungeon.zones

-- Rooms of just a given zone and its sub-zones.
localRooms : Zone -> List Room
localRooms zone =
  zone.rooms ++

  -- TODO: Fiddly lambda construction to unwrap Regions -- is there a better way?
  ( (\(Regions zones) -> List.concatMap localRooms zones)
    zone.regions
  )

-- Look up a room by key.
-- Takes a zone because the README says keys are only unique within a zone.
--
-- Does not check the key given actually exists in this zone.
--
-- TODO: assumes keys are unique, which we don't know yet.
findRoom : String -> Zone -> Maybe Room
findRoom key zone =
  let
    matchingRooms =
      List.filter
        (\room -> room.key == key)
        (localRooms zone)
  in
    case matchingRooms of
      [] ->
        Nothing

      [ room ] ->
        (Just room)

      room :: rest ->
        Nothing
        -- TODO: should be an error but the calling code isn't prepared to handle it;
        -- we really should validate this in the initial JSON parse.
        -- Err ( "The key '" ++ key ++  "' seems to have been used for more than one room.")

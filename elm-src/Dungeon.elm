module Dungeon exposing (Dungeon, Room, Zone, Regions(..), Connection, rooms)

-- Types representing an Aeldardin dungeon.
-- These may eventually need to be parametric or something to allow addons with their own types.

type alias Dungeon =
  { title : String
  , zones : List Zone
  }

type alias Zone =
  { rooms : List Room
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

module Dungeon exposing (Dungeon, Room, Zone, Regions(..), Connection)

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

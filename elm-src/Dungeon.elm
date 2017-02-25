module Dungeon exposing (Dungeon)

-- Types representing an Aeldardin dungeon.
-- These may eventually need to be parametric or something to allow addons with their own types.

type alias Dungeon =
  { title : String }
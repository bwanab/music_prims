defmodule MusicPrimsTest do
  use ExUnit.Case
  doctest MusicPrims

  describe "scale tests" do
    test "C Scale sanity" do
      assert MusicPrims.scale(:C) == [C: 24, D: 26, E: 28, F: 29, G: 31, A: 33, B: 35]
    end
    test "C major notes match A minor" do
      c_major_notes = MapSet.new(Enum.map(MusicPrims.scale(:C, :major), fn {n, _} -> n end))
      a_minor_notes = MapSet.new(Enum.map(MusicPrims.scale(:A, :minor), fn {n, _} -> n end))
      assert c_major_notes == a_minor_notes
    end
  end

end

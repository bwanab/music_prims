defmodule ArpeggioTest do
  use ExUnit.Case
  doctest Arpeggio

  describe "Arpeggio.new/3" do
    test "creates an arpeggio from a chord and pattern" do
      chord = Chord.new({{:C, 4}, :major}, 1.0)
      arpeggio = Arpeggio.new(chord, :up, 2.0)

      assert arpeggio.chord == chord
      assert arpeggio.pattern == :up
      assert arpeggio.duration == 2.0
    end
  end

  describe "Arpeggio.to_notes/1" do
    test "converts up pattern to notes" do
      chord = Chord.new({{:C, 4}, :major}, 1.0)
      arpeggio = Arpeggio.new(chord, :up, 3.0)
      notes = Arpeggio.to_notes(arpeggio)

      assert length(notes) == 3
      assert Enum.map(notes, & &1.note) == [{:C, 4}, {:E, 4}, {:G, 4}]
      assert Enum.all?(notes, & &1.duration == 1.0)
    end

    test "converts down pattern to notes" do
      chord = Chord.new({{:C, 4}, :major}, 1.0)
      arpeggio = Arpeggio.new(chord, :down, 3.0)
      notes = Arpeggio.to_notes(arpeggio)

      assert length(notes) == 3
      assert Enum.map(notes, & &1.note) == [{:G, 4}, {:E, 4}, {:C, 4}]
      assert Enum.all?(notes, & &1.duration == 1.0)
    end

    test "converts up_down pattern to notes" do
      chord = Chord.new({{:C, 4}, :major}, 1.0)
      arpeggio = Arpeggio.new(chord, :up_down, 4.0)
      notes = Arpeggio.to_notes(arpeggio)

      assert length(notes) == 4
      assert Enum.map(notes, & &1.note) == [{:C, 4}, {:E, 4}, {:G, 4}, {:E, 4}]
      assert Enum.all?(notes, & &1.duration == 1.0)
    end

    test "converts down_up pattern to notes" do
      chord = Chord.new({{:C, 4}, :major}, 1.0)
      arpeggio = Arpeggio.new(chord, :down_up, 4.0)
      notes = Arpeggio.to_notes(arpeggio)

      assert length(notes) == 4
      assert Enum.map(notes, & &1.note) == [{:G, 4}, {:E, 4}, {:C, 4}, {:E, 4}]
      assert Enum.all?(notes, & &1.duration == 1.0)
    end

    test "converts explicit pattern to notes" do
      chord = Chord.new({{:C, 4}, :major}, 1.0)
      arpeggio = Arpeggio.new(chord, [2, 1, 3], 3.0)
      notes = Arpeggio.to_notes(arpeggio)

      assert length(notes) == 3
      assert Enum.map(notes, & &1.note) == [{:E, 4}, {:C, 4}, {:G, 4}]
      assert Enum.all?(notes, & &1.duration == 1.0)
    end
  end

  describe "Arpeggio.repeat/2" do
    test "repeats an arpeggio the specified number of times" do
      chord = Chord.new({{:C, 4}, :major}, 1.0)
      arpeggio = Arpeggio.new(chord, :up, 3.0)
      repeated = Arpeggio.repeat(arpeggio, 2)

      assert repeated.duration == 6.0
      notes = Arpeggio.to_notes(repeated)
      assert length(notes) == 6
      assert Enum.map(notes, & &1.note) == [{:C, 4}, {:E, 4}, {:G, 4}, {:C, 4}, {:E, 4}, {:G, 4}]
      assert Enum.all?(notes, & &1.duration == 1.0)
    end
  end

  describe "Sonority protocol implementation" do
    test "returns correct duration" do
      chord = Chord.new({{:C, 4}, :major}, 1.0)
      arpeggio = Arpeggio.new(chord, :up, 3.0)
      assert Sonority.duration(arpeggio) == 3.0
    end

    test "returns correct type" do
      chord = Chord.new({{:C, 4}, :major}, 1.0)
      arpeggio = Arpeggio.new(chord, :up, 3.0)
      assert Sonority.type(arpeggio) == :arpeggio
    end
  end
end

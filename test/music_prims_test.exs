defmodule MusicPrimsTest do
  use ExUnit.Case
  import MusicPrims
  import ChordPrims
  doctest MusicPrims

  describe "scale tests" do
    test "Scale sanity" do
      assert major_scale(:C) == [C: 0, D: 0, E: 0, F: 0, G: 0, A: 0, B: 0]
      assert major_scale(:C!) == [C!: 0, D!: 0, F: 0, F!: 0, G!: 0, A!: 0, C: 1]
      assert major_scale(:F) == [F: 0, G: 0, A: 0, Bb: 0, C: 1, D: 1, E: 1]
    end
    test "C major notes match A minor" do
      c_major_notes = MapSet.new(Enum.map(major_scale(:C), fn {n, _} -> n end))
      a_minor_notes = MapSet.new(Enum.map(minor_scale(:A), fn {n, _} -> n end))
      assert c_major_notes == a_minor_notes
    end
    test "key signitures are correct" do
      assert key(:major, 3, :sharps) == :A
      assert key(:minor, 0, :sharps) == :A
      assert key(:major, 3, :flats) == :Eb
      assert key(:minor, 0, :flats) == :Eb
    end
    test "fifths and fourths" do
      assert circle_of_5ths() ==
        Stream.iterate({:C, 1}, fn a -> next_fifth(a) end)
        |> Enum.take(12)
        |> Enum.map(fn {a,_} -> a end)
      assert circle_of_4ths() ==
        Stream.iterate({:C, 1}, fn a -> next_fourth(a) end)
        |> Enum.take(12)
        |> Enum.map(fn {a,_} -> a end)
    end
    test "chromatic scale" do
      assert chromatic_scale({:C, 0}) |> Enum.take(4) == [C: 0, C!: 0, D: 0, D!: 0]
    end
    test "first 5 notes of :C :major same as last 5 notes of :A :minor" do
      assert major_scale(:C, 1) |> Enum.take(5) ==
        minor_scale(:A, 0) |> Enum.drop(2)
    end
    test "last 6 notes of :C :major same as first 6 notes of :D :dorian" do
      assert major_scale(:C, 1) |> Enum.drop(1) ==
        dorian_scale(:D, 1) |> Enum.take(6)
    end
    test "first 3 notes of pentatonic same as first 3 notes of blues" do
      assert pent_scale(:A) |> Enum.take(3) ==
        blues_scale(:A) |> Enum.take(3)
    end
    test "last 3 notes of pentatonic same as last 3 notes of blues" do
      assert pent_scale(:A) |> Enum.drop(3) ==
        blues_scale(:A) |> Enum.drop(4)
    end

    test "create a chord" do
      assert major_chord(:F) == [F: 0, A: 0, C: 1]
    end
    test "first inversion of a chord" do
      assert major_chord(:F)
        |> first_inversion() == [A: 0, C: 1, F: 1]
    end
    test "second inversion of a chord" do
      assert major_chord(:F)
        |> second_inversion() == [C: 1, F: 1, A: 1]
    end
    test "third inversion of a chord" do
      assert major_seventh_chord(:F)
        |> third_inversion() == [E: 1, F: 1, A: 1, C: 2]
    end

    test "midi conversions" do
      assert major_scale(:C) |> to_midi == [12, 14, 16, 17, 19, 21, 23]
      assert major_seventh_chord(:F) |> to_midi == [17, 21, 24, 28]
      assert major_seventh_chord(:F) |> third_inversion |> to_midi == [28, 29, 33, 36]
    end

    test "chord sequence reification" do
      assert chord_syms_to_chords([:I, :IV, :vi, :V], :C) == [{:C, :major}, {:F, :major}, {:A, :minor}, {:G, :major}]
    end

    test "chord sequence reification and to midi" do
      assert Enum.map(chord_syms_to_chords([:I, :IV, :vi, :V], :G), &(chord_to_notes(&1))
      |> to_midi
      |> Enum.map(fn a -> to_string(a) end)) ==
        [
          ["31", "35", "38"],
          ["24", "28", "31"],
          ["28", "31", "35"],
          ["26", "30", "33"]
        ]
    end

  end

end

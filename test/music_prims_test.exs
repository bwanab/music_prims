defmodule MusicPrimsTest do
  use ExUnit.Case
  import MusicPrims
  doctest MusicPrims

  describe "scale tests" do
    test "Scale sanity" do
      assert MusicPrims.major_scale(:C) == [C: 0, D: 0, E: 0, F: 0, G: 0, A: 0, B: 0]
      assert MusicPrims.major_scale(:C!) == [C!: 0, D!: 0, F: 0, F!: 0, G!: 0, A!: 0, C: 1]
    end
    test "C major notes match A minor" do
      c_major_notes = MapSet.new(Enum.map(MusicPrims.major_scale(:C), fn {n, _} -> n end))
      a_minor_notes = MapSet.new(Enum.map(MusicPrims.minor_scale(:A), fn {n, _} -> n end))
      assert c_major_notes == a_minor_notes
    end
    test "key signitures are correct" do
      assert MusicPrims.key(:major, 3, :sharps) == :A
      assert MusicPrims.key(:minor, 0, :sharps) == :A
      assert MusicPrims.key(:major, 3, :flats) == :D!
      assert MusicPrims.key(:minor, 0, :flats) == :D!
    end
    test "fifths and fourths" do
      assert MusicPrims.circle_of_5ths ==
        Stream.iterate({:C, 1}, fn a -> MusicPrims.next_fifth(a) end)
        |> Enum.take(12)
        |> Enum.map(fn {a,_} -> a end)
      assert MusicPrims.circle_of_4ths ==
        Stream.iterate({:C, 1}, fn a -> MusicPrims.next_fourth(a) end)
        |> Enum.take(12)
        |> Enum.map(fn {a,_} -> a end)
    end
    test "chromatic scale" do
      assert MusicPrims.chromatic_scale({:C, 0}) |> Enum.take(4) == [C: 0, C!: 0, D: 0, D!: 0]
    end
    test "first 5 notes of :C :major same as last 5 notes of :A :minor" do
      assert MusicPrims.major_scale(:C, 1) |> Enum.take(5) ==
        MusicPrims.minor_scale(:A, 0) |> Enum.drop(2)
    end
    test "last 6 notes of :C :major same as first 6 notes of :D :dorian" do
      assert MusicPrims.major_scale(:C, 1) |> Enum.drop(1) ==
        MusicPrims.dorian_scale(:D, 1) |> Enum.take(6)
    end
    test "first 3 notes of pentatonic same as first 3 notes of blues" do
      assert MusicPrims.pent_scale(:A) |> Enum.take(3) ==
        MusicPrims.blues_scale(:A) |> Enum.take(3)
    end
    test "last 3 notes of pentatonic same as last 3 notes of blues" do
      assert MusicPrims.pent_scale(:A) |> Enum.drop(3) ==
        MusicPrims.blues_scale(:A) |> Enum.drop(4)
    end

    test "create a chord" do
      assert MusicPrims.major_chord(:F) == [F: 0, A: 0, C: 1]
    end
    test "first inversion of a chord" do
      assert MusicPrims.major_chord(:F)
        |> MusicPrims.first_inversion() == [A: 0, C: 1, F: 1]
    end
    test "second inversion of a chord" do
      assert MusicPrims.major_chord(:F)
        |> MusicPrims.second_inversion() == [C: 1, F: 1, A: 1]
    end
    test "third inversion of a chord" do
      assert MusicPrims.major_seventh_chord(:F)
        |> MusicPrims.third_inversion() == [E: 1, F: 1, A: 1, C: 2]
    end

    test "midi conversions" do
      assert major_scale(:C) |> to_midi == [24, 26, 28, 29, 31, 33, 35]
      assert major_seventh_chord(:F) |> to_midi == [29, 33, 36, 40]
      assert major_seventh_chord(:F) |> third_inversion |> to_midi == [40, 41, 45, 48]
    end

  end

end

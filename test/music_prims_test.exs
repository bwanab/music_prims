defmodule MusicPrimsTest do
  use ExUnit.Case
  doctest MusicPrims

  describe "scale tests" do
    test "Scale sanity" do
      assert MusicPrims.scale(:C) == [C: 24, D: 26, E: 28, F: 29, G: 31, A: 33, B: 35]
      assert MusicPrims.scale(:C!) == [C!: 25, D!: 27, F: 29, F!: 30, G!: 32, A!: 34, C: 36]
    end
    test "C major notes match A minor" do
      c_major_notes = MapSet.new(Enum.map(MusicPrims.scale(:C, :major), fn {n, _} -> n end))
      a_minor_notes = MapSet.new(Enum.map(MusicPrims.scale(:A, :minor), fn {n, _} -> n end))
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
      assert MusicPrims.chromatic_scale(:C) |> Enum.take(4) == [C: 24, C!: 25, D: 26, D!: 27]
    end
    test "first 5 notes of major scale of :C :majore same as last 5 notes of :A :minor" do
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

  end

end

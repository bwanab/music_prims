defmodule SonorityTest do
  use ExUnit.Case
  doctest Sonority

  describe "Sonority behavior" do
    test "get_type returns the correct type" do
      note = Note.new({:C, 4})
      rest = Rest.new(1.0)
      chord = Chord.new([note], 1.0)

      assert Sonority.get_type(note) == :note
      assert Sonority.get_type(rest) == :rest
      assert Sonority.get_type(chord) == :chord
    end

    test "duration callback works through Sonority.get_type" do
      note = Note.new({:C, 4}, duration: 2.0)
      rest = Rest.new(1.5)
      chord = Chord.new([note], 0.5)

      assert Note.duration(note) == 2.0
      assert Rest.duration(rest) == 1.5
      assert Chord.duration(chord) == 0.5
    end

    test "mapping a list of sonorities returns correct types" do
      note = Note.new({:C, 4})
      chord1 = Chord.new([note], 1.0)
      chord2 = Chord.new({{:C, 4}, :major}, 1.0)
      rest = Rest.new(1.0)

      sonorities = [note, chord1, chord2, rest]
      types = Enum.map(sonorities, &Sonority.get_type/1)

      assert types == [:note, :chord, :chord, :rest]
    end

  end
end

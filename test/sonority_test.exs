defmodule SonorityTest do
  use ExUnit.Case
  doctest Sonority


  describe "Sonority behavior" do
    test "get_type returns the correct type" do
      note = Note.new({:C, 4})
      rest = Rest.new(1)
      chord = Chord.new([note], 1)

      assert Sonority.type(note) == :note
      assert Sonority.type(rest) == :rest
      assert Sonority.type(chord) == :chord
    end

    test "duration callback works through Sonority.get_type" do
      note = Note.new({:C, 4}, duration: 2)
      rest = Rest.new(1)
      chord = Chord.new([note], 2)

      assert Sonority.duration(note) == 2
      assert Sonority.duration(rest) == 1
      assert Sonority.duration(chord) == 2
    end

    test "mapping a list of sonorities returns correct types" do
      note = Note.new({:C, 4})
      chord1 = Chord.new([note], 1)
      chord2 = Chord.new(:C, :major, 4, 1)
      rest = Rest.new(1)

      sonorities = [note, chord1, chord2, rest]
      types = Enum.map(sonorities, &Sonority.type/1)

      assert types == [:note, :chord, :chord, :rest]
    end

    @spec create_sonorities() :: [Sonority.t()]
    defp create_sonorities do
      [
        Note.new({:C, 4}, duration: 1),
        Rest.new(1),
        Chord.new(:A, :major, 4, 1),
        Note.new({:E, 4}, duration: 1),
        Note.new({:F, 4}, duration: 1)
      ]
    end

    test "Sonority behavior call function with list of mixed sonorities" do
      sonorities = create_sonorities()
      types = Enum.map(sonorities, &Sonority.type/1)
      assert [:note, :rest, :chord, :note, :note] == types
    end
  end

end

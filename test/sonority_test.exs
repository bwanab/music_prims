defmodule SonorityTest do
  use ExUnit.Case
  doctest Sonority


  describe "Sonority behavior" do
    test "get_type returns the correct type" do
      note = Note.new({:C, 4})
      rest = Rest.new(1.0)
      chord = Chord.new([note], 1.0)

      assert Sonority.type(note) == :note
      assert Sonority.type(rest) == :rest
      assert Sonority.type(chord) == :chord
    end

    test "duration callback works through Sonority.get_type" do
      note = Note.new({:C, 4}, duration: 2.0)
      rest = Rest.new(1.5)
      chord = Chord.new([note], 0.5)

      assert Sonority.duration(note) == 2.0
      assert Sonority.duration(rest) == 1.5
      assert Sonority.duration(chord) == 0.5
    end

    test "mapping a list of sonorities returns correct types" do
      note = Note.new({:C, 4})
      chord1 = Chord.new([note], 1.0)
      chord2 = Chord.new({{:C, 4}, :major}, 1.0)
      rest = Rest.new(1.0)

      sonorities = [note, chord1, chord2, rest]
      types = Enum.map(sonorities, &Sonority.type/1)

      assert types == [:note, :chord, :chord, :rest]
    end

    @spec create_sonorities() :: [Sonority.t()]
    defp create_sonorities do
      [
        Note.new({:C, 4}, duration: 1.0),
        Rest.new(1.0),
        Chord.new_from_root(:A, :major, 4, 1.0),
        Note.new({:E, 4}, duration: 1.0),
        Note.new({:F, 4}, duration: 1.0)
      ]
    end

    test "Sonority behavior call function with list of mixed sonorities" do
      sonorities = create_sonorities()
      types = Enum.map(sonorities, &Sonority.type/1)
      assert [:note, :rest, :chord, :note, :note] == types
    end
  end

end

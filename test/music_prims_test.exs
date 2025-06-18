defmodule MusicPrimsTest do
  use ExUnit.Case
  import MusicPrims
  import Chord
  import Scale
  doctest MusicPrims

  # Helper function to normalize output for test assertions
  # Converts both old style keyword lists and new Note structs to a keyword list
  def normalize(notes) do
    Enum.map(notes, fn %Note{note: note, octave: octave} -> {note, octave} end)
    # cond do
    #   is_list(notes) && match?([%Note{} | _], notes) ->
    #     Note.to_keyword_list(notes)
    #   is_list(notes) && Keyword.keyword?(notes) ->
    #     notes
    #   true ->
    #     notes  # Return as is for other types
    # end
  end

  describe "scale tests" do
    test "Scale sanity" do
      assert normalize(major_scale(:C)) == [C: 0, D: 0, E: 0, F: 0, G: 0, A: 0, B: 0]
      assert Scale.enharmonic_equal?(normalize(major_scale(:C!)), [C!: 0, D!: 0, F: 0, F!: 0, G!: 0, A!: 0, C: 1])
      assert Scale.enharmonic_equal?(normalize(major_scale(:F)), [F: 0, G: 0, A: 0, Bb: 0, C: 1, D: 1, E: 1])
    end
    test "C major notes match A minor" do
      c_major_notes = MapSet.new(Enum.map(normalize(major_scale(:C)), fn {n, _} -> n end))
      a_minor_notes = MapSet.new(Enum.map(normalize(minor_scale(:A)), fn {n, _} -> n end))
      assert c_major_notes == a_minor_notes
    end
    test "key signitures are correct" do
      assert key(:major, 3, :sharps) == :A
      assert key(:minor, 0, :sharps) == :A
      assert key(:major, 3, :flats) == :Eb
      assert key(:minor, 0, :flats) == :Eb
    end
    test "fifths and fourths" do
      # Check that the circle_of_5ths function returns the expected list
      assert circle_of_5ths() == [:C, :G, :D, :A, :E, :B, :Gb, :Db, :Ab, :Eb, :Bb, :F]

      # Check that the circle_of_4ths function returns the expected list
      assert circle_of_4ths() == [:C, :F, :A!, :D!, :G!, :C!, :F!, :B, :E, :A, :D, :G]
    end
    test "first 5 notes of :C :major same as last 5 notes of :A :minor" do
      assert normalize(major_scale(:C, octave: 1) |> Enum.take(5)) ==
        normalize(minor_scale(:A, octave: 0) |> Enum.drop(2))
    end
    test "last 6 notes of :C :major same as first 6 notes of :D :dorian" do
      assert normalize(major_scale(:C, octave: 1) |> Enum.drop(1)) ==
        normalize(modal_scale(:D, :dorian, octave: 1) |> Enum.take(6))
    end
    test "first 3 notes of pentatonic same as first 3 notes of blues" do
      assert normalize(pent_scale(:A) |> Enum.take(3)) ==
        normalize(blues_scale(:A) |> Enum.take(3))
    end
    test "last 3 notes of pentatonic same as last 3 notes of blues" do
      assert normalize(pent_scale(:A) |> Enum.drop(3)) ==
        normalize(blues_scale(:A) |> Enum.drop(4))
    end

    test "create a chord" do
      assert normalize(major_chord(:F)) == [F: 0, A: 0, C: 1]
    end
    test "first inversion of a chord" do
      assert normalize(major_chord(:F)
        |> first_inversion()) == [A: 0, C: 1, F: 1]
    end
    test "second inversion of a chord" do
      assert normalize(major_chord(:F)
        |> second_inversion()) == [C: 1, F: 1, A: 1]
    end
    test "third inversion of a chord" do
      assert normalize(major_seventh_chord(:F)
        |> third_inversion()) == [E: 1, F: 1, A: 1, C: 2]
    end

    test "midi conversions" do
      assert major_scale(:C) |> MidiNote.to_midi == [12, 14, 16, 17, 19, 21, 23]
      assert major_seventh_chord(:F) |> MidiNote.to_midi == [17, 21, 24, 28]
      assert major_seventh_chord(:F) |> third_inversion |> MidiNote.to_midi == [28, 29, 33, 36]
    end

    test "octave_up on all notes" do
      assert normalize(major_chord(:C) |> Note.octave_up) == [C: 1, E: 1, G: 1]
      assert normalize(major_chord(:F) |> Note.octave_up) == [F: 1, A: 1, C: 2]
      assert normalize(minor_chord(:A) |> Note.octave_up) == [A: 1, C: 2, E: 2]
    end

    test "bump_octave up on all notes" do
      assert normalize(major_chord(:C) |> Note.bump_octave(:up)) == [C: 1, E: 1, G: 1]
      assert normalize(major_chord(:F) |> Note.bump_octave(:up)) == [F: 1, A: 1, C: 2]
    end

    test "bump_octave down on all notes" do
      assert normalize(major_chord(:C, octave: 1) |> Note.bump_octave(:down)) == [C: 0, E: 0, G: 0]
      assert normalize(major_chord(:F, octave: 1) |> Note.bump_octave(:down)) == [F: 0, A: 0, C: 1]
    end

    test "bump_octave on single position" do
      assert normalize(major_chord(:C) |> Note.bump_octave(1, :up)) == [C: 0, E: 1, G: 0]
      assert normalize(major_chord(:F, octave: 1) |> Note.bump_octave(2, :down)) == [F: 1, A: 1, C: 1]
    end

    test "scale tests chord sequence reification" do
      result = roman_numerals_to_chords([:I, :IV, :vi, :V], :C, 0, :major)
      assert result == [
        {{:C, 0}, :major},
        {{:F, 0}, :major},
        {{:A, 0}, :minor},
        {{:G, 0}, :major}
      ]
    end

    test "scale tests chord sequence reification and to midi" do
      result = Enum.map(roman_numerals_to_chords([:I, :IV, :vi, :V], :G, 0, :major), fn {{key, octave}, scale_type} ->
        chord_to_notes(key, octave: octave, scale_type: scale_type)
      end)
      |> Enum.map(&(MidiNote.to_midi(&1)))
      assert result == [
        [19, 23, 26],  # G major chord
        [24, 28, 31],  # C major chord
        [28, 31, 35],  # E minor chord
        [26, 30, 33]   # D major chord
      ]
    end

    test "scale_interval returns correct intervals for different modes" do
      # Major mode (0) should return standard major scale intervals
      assert scale_interval(:major) == [0, 2, 4, 5, 7, 9, 11]

      # Dorian mode (1) should return dorian scale intervals
      assert scale_interval(:dorian) == [0, 2, 3, 5, 7, 9, 10]

      # Minor mode (5) should return natural minor scale intervals
      assert scale_interval(:minor) == [0, 2, 3, 5, 7, 8, 10]

      # Locrian mode (6) should return locrian scale intervals
      assert scale_interval(:locrian) == [0, 1, 3, 5, 6, 8, 10]
    end

    test "equivalent_key finds correct equivalent keys between modes" do
      # A minor is equivalent to C major
      assert equivalent_key(:A, :minor, :major) == :C

      # D dorian is equivalent to C major
      assert equivalent_key(:D, :dorian, :major) == :C

      # D dorian is equivalent to A minor
      assert equivalent_key(:D, :dorian, :minor) == :A

      # G mixolydian is equivalent to C major
      assert equivalent_key(:G, :mixolodian, :major) == :C

      # E phrygian is equivalent to C major
      assert equivalent_key(:E, :phrygian, :major) == :C
    end

    test "modal_scale generates correct scales for different modes" do
      # C major scale
      assert normalize(modal_scale(:C, :major, octave: 0)) == [C: 0, D: 0, E: 0, F: 0, G: 0, A: 0, B: 0]

      # D dorian scale (should be same notes as C major)
      assert normalize(modal_scale(:D, :dorian, octave: 0)) == [D: 0, E: 0, F: 0, G: 0, A: 0, B: 0, C: 1]

      # A minor scale (should be same notes as C major)
      assert normalize(modal_scale(:A, :minor, octave: 0)) == [A: 0, B: 0, C: 1, D: 1, E: 1, F: 1, G: 1]

      # G mixolydian scale (should be same notes as C major)
      assert normalize(modal_scale(:G, :mixolodian, octave: 0)) == [G: 0, A: 0, B: 0, C: 1, D: 1, E: 1, F: 1]

      # E phrygian scale (should be same notes as C major)
      assert normalize(modal_scale(:E, :phrygian, octave: 0)) == [E: 0, F: 0, G: 0, A: 0, B: 0, C: 1, D: 1]
    end
  end

end

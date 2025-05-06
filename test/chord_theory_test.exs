defmodule ChordTheoryTest do
  use ExUnit.Case
  doctest ChordTheory

  describe "ChordTheory.get_standard_notes/3" do
    test "returns correct notes for major chord" do
      notes = ChordTheory.get_standard_notes(:C, :major)
      assert length(notes) == 3
      # Verify the note names are C, E, G
      note_names = Enum.map(notes, fn %Note{note: {key, _}} -> key end)
      assert note_names == [:C, :E, :G]
    end

    test "returns correct notes for minor chord" do
      notes = ChordTheory.get_standard_notes(:A, :minor)
      note_names = Enum.map(notes, fn %Note{note: {key, _}} -> key end)
      assert note_names == [:A, :C, :E]
    end

    test "returns correct notes for seventh chord" do
      notes = ChordTheory.get_standard_notes(:G, :dominant_seventh)
      note_names = Enum.map(notes, fn %Note{note: {key, _}} -> key end)
      assert note_names == [:G, :B, :D, :F]
    end
  end

  describe "ChordTheory.infer_chord_type/1" do
    test "identifies a major chord" do
      notes = [
        %Note{note: {:C, 4}},
        %Note{note: {:E, 4}},
        %Note{note: {:G, 4}}
      ]
      assert ChordTheory.infer_chord_type(notes) == {:C, :major}
    end

    test "identifies a minor chord" do
      notes = [
        %Note{note: {:A, 3}},
        %Note{note: {:C, 4}},
        %Note{note: {:E, 4}}
      ]
      assert ChordTheory.infer_chord_type(notes) == {:A, :minor}
    end

    test "first inversion of a chord" do
      notes = ChordPrims.first_inversion(ChordPrims.major_chord(:F, 3))
      assert ChordTheory.infer_chord_type(notes) == {:F, :major}
    end

    test "second inversion of a chord" do
      notes = ChordPrims.second_inversion(ChordPrims.major_chord(:F, 3))
      assert ChordTheory.infer_chord_type(notes) == {:F, :major}
    end
  end

  describe "ChordTheory.chord_degrees/2" do
    test "returns correct degrees for major chord" do
      assert ChordTheory.chord_degrees(:C, :major) == [1, 3, 5]
    end

    test "returns correct degrees for dominant seventh chord" do
      assert ChordTheory.chord_degrees(:G, :dominant_seventh) == [1, 3, 5, 7]
    end
  end
end

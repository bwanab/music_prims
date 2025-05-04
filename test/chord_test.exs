defmodule ChordTest do
  use ExUnit.Case
  doctest Chord
  
  describe "Chord.new/2 from notes" do
    test "creates a chord from a list of notes" do
      notes = [
        Note.new({:C, 4}),
        Note.new({:E, 4}),
        Note.new({:G, 4})
      ]
      chord = Chord.new(notes, 1.0)
      assert chord.notes == notes
      assert chord.duration == 1.0
      assert chord.root == :C
      assert chord.quality == :major
    end
  end
  
  describe "Chord.new/2 from chord symbol" do
    test "creates a chord from a chord symbol" do
      chord = Chord.new({{:C, 4}, :major}, 1.0)
      assert chord.duration == 1.0
      assert chord.root == :C
      assert chord.quality == :major
      assert length(chord.notes) == 3
    end
  end
  
  describe "Chord.from_root_and_quality/4" do
    test "creates a chord with explicit root and quality" do
      chord = Chord.from_root_and_quality(:D, :minor, 3, 2.0)
      assert chord.root == :D
      assert chord.quality == :minor
      assert chord.duration == 2.0
      
      # Check that notes match D minor
      note_names = Enum.map(chord.notes, fn %Note{note: {key, _}} -> key end)
      assert note_names == [:D, :F, :A]
    end
  end
  
  describe "Chord modifications" do
    setup do
      {:ok, chord: Chord.from_root_and_quality(:C, :major)}
    end
    
    test "with_bass sets the bass note", %{chord: chord} do
      bass_chord = Chord.with_bass(chord, {:G, 3})
      assert bass_chord.bass_note == {:G, 3}
    end
    
    test "with_additions adds notes", %{chord: chord} do
      add9 = Note.new({:D, 5})
      add_chord = Chord.with_additions(chord, [add9])
      assert add_chord.additions == [add9]
    end
    
    test "with_omissions removes notes", %{chord: chord} do
      no_fifth = Chord.with_omissions(chord, [5])
      assert no_fifth.omissions == [5]
      
      # The to_notes method should omit the fifth
      notes = Chord.to_notes(no_fifth)
      note_names = Enum.map(notes, fn %Note{note: {key, _}} -> key end)
      assert length(note_names) == 2
      assert :G not in note_names
    end
  end
  
  describe "Sonority protocol" do
    test "type returns :chord" do
      chord = Chord.from_root_and_quality(:C, :major)
      assert Sonority.type(chord) == :chord
    end
    
    test "duration returns the chord duration" do
      chord = Chord.from_root_and_quality(:C, :major, 0, 2.5)
      assert Sonority.duration(chord) == 2.5
    end
  end
end
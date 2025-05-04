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
  
  describe "Chord.from_roman_numeral/5" do
    test "creates a major I chord in C" do
      chord = Chord.from_roman_numeral(:I, :C, 4, 4.0)
      assert chord.root == :C
      assert chord.quality == :major
      assert chord.duration == 4.0
      
      # Check that notes match C major
      note_names = Enum.map(chord.notes, fn %Note{note: {key, _}} -> key end)
      assert note_names == [:C, :E, :G]
    end
    
    test "creates a minor ii chord in C" do
      chord = Chord.from_roman_numeral(:ii, :C, 4, 2.0)
      assert chord.root == :D
      assert chord.quality == :minor
      assert chord.duration == 2.0
      
      # Check that notes match D minor
      note_names = Enum.map(chord.notes, fn %Note{note: {key, _}} -> key end)
      assert note_names == [:D, :F, :A]
    end
    
    test "creates a dominant V7 chord in G" do
      chord = Chord.from_roman_numeral(:V7, :G, 3, 1.0)
      assert chord.root == :D
      assert chord.quality == :dominant_seventh
      assert chord.duration == 1.0
      
      # Check that notes match D7
      note_names = Enum.map(chord.notes, fn %Note{note: {key, _}} -> key end)
      assert note_names == [:D, :F!, :A, :C]
    end
    
    test "creates a major III chord in C minor" do
      chord = Chord.from_roman_numeral(:III, :C, 4, 1.0, :minor)
      
      # The chord is stored as a D# major chord (using D! in our system) 
      # but the notes themselves are represented with their enharmonic Eb major equivalents
      assert chord.root == :D!
      assert chord.quality == :major
      assert chord.duration == 1.0
      
      # The actual notes are in Eb major (enharmonic equivalent)
      note_names = Enum.map(chord.notes, fn %Note{note: {key, _}} -> key end)
      assert note_names == [:Eb, :G, :Bb]
    end
    
    test "creates a minor i chord in A minor" do
      chord = Chord.from_roman_numeral(:i, :A, 4, 2.0, :minor)
      assert chord.root == :A
      assert chord.quality == :minor
      assert chord.duration == 2.0
      
      # Check that notes match A minor
      note_names = Enum.map(chord.notes, fn %Note{note: {key, _}} -> key end)
      assert note_names == [:A, :C, :E]
    end
  end
  
  describe "Chord.has_root_enharmonic_with?/2" do
    test "identifies enharmonic root equivalence with note keys" do
      # Create a chord with D# root (III in C minor)
      chord = Chord.from_roman_numeral(:III, :C, 4, 1.0, :minor)
      
      # Should recognize Eb as enharmonically equivalent to D#
      assert Chord.has_root_enharmonic_with?(chord, :Eb)
      
      # Should recognize D# as the actual root
      assert Chord.has_root_enharmonic_with?(chord, :D!)
      
      # Should not match non-equivalent notes
      refute Chord.has_root_enharmonic_with?(chord, :D)
      refute Chord.has_root_enharmonic_with?(chord, :E)
    end
    
    test "identifies enharmonic root equivalence with note tuples" do
      # Create a chord with F# root (V in B major)
      chord = Chord.from_roman_numeral(:V, :B, 3, 1.0)
      
      # Should recognize Gb as enharmonically equivalent to F#
      assert Chord.has_root_enharmonic_with?(chord, {:Gb, 3})
      
      # Should recognize F# as the actual root
      assert Chord.has_root_enharmonic_with?(chord, {:F!, 3})
      
      # Should not match non-equivalent notes
      refute Chord.has_root_enharmonic_with?(chord, {:F, 3})
      refute Chord.has_root_enharmonic_with?(chord, {:G, 3})
      
      # Should match based on pitch class, ignoring octave differences
      assert Chord.has_root_enharmonic_with?(chord, {:F!, 4})
      assert Chord.has_root_enharmonic_with?(chord, {:Gb, 4})
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
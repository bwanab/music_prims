defmodule NoteTest do
  use ExUnit.Case
  doctest Note

  describe "Note.new/2" do
    test "creates a note with no duration or velocity" do
      note = Note.new({:C, 4})
      assert note.note == {:C, 4}
      assert note.duration == nil
      assert note.velocity == nil
    end

    test "creates a note with both duration and velocity specified" do
      note = Note.new({:D, 3}, duration: 2, velocity: 80)
      assert note.note == {:D, 3}
      assert note.duration == 2
      assert note.velocity == 80
    end

    test "creates a note with duration but no velocity, defaults velocity to 100" do
      note = Note.new({:E, 5}, duration: 1.5)
      assert note.note == {:E, 5}
      assert note.duration == 1.5
      assert note.velocity == 100
    end

    test "creates a note with velocity but no duration, defaults duration to 1" do
      note = Note.new({:F!, 2}, velocity: 64)
      assert note.note == {:F!, 2}
      assert note.duration == 1
      assert note.velocity == 64
    end
  end

  describe "Note.to_string/1" do
    test "formats a natural note correctly without duration" do
      note = Note.new({:C, 4})
      assert Note.to_string(note) == "C4"
    end

    test "formats a sharp note correctly without duration" do
      note = Note.new({:C!, 4})
      assert Note.to_string(note) == "C#4"
    end

    test "formats a flat note correctly without duration" do
      # Assumes flat notes are represented as Bb, Eb, etc.
      note = Note.new({:Bb, 3})
      assert Note.to_string(note) == "Bb3"
    end

    test "formats a quarter note (duration 1)" do
      note = Note.new({:C, 4}, duration: 1)
      assert Note.to_string(note) == "C4*1/4"
    end

    test "formats a half note (duration 2)" do
      note = Note.new({:D, 3}, duration: 2)
      assert Note.to_string(note) == "D3*2/4"
    end

    test "formats an eighth note (duration 0.5)" do
      note = Note.new({:G, 3}, duration: 0.5)
      assert Note.to_string(note) == "G3*1/8"
    end

    test "formats a sixteenth note (duration 0.25)" do
      note = Note.new({:A, 5}, duration: 0.25)
      assert Note.to_string(note) == "A5*1/16"
    end

    test "formats a whole note (duration 4)" do
      note = Note.new({:E, 2}, duration: 4)
      assert Note.to_string(note) == "E2*4/4"
    end

    test "formats a custom duration" do
      note = Note.new({:F, 4}, duration: 3)
      assert Note.to_string(note) == "F4*3/4"
    end
  end

  describe "Note.midi_to_note/3" do
    test "converts middle C (MIDI 60) to Note struct" do
      note = Note.midi_to_note(60, 1, 100)
      assert note.note == {:C, 4}
      assert note.duration == 1
      assert note.velocity == 100
    end

    test "converts MIDI note 72 to C5" do
      note = Note.midi_to_note(72, 2, 80)
      assert note.note == {:C, 5}
      assert note.duration == 2
      assert note.velocity == 80
    end

    test "converts MIDI note 61 to C#4" do
      note = Note.midi_to_note(61, 0.5, 90)
      assert note.note == {:C!, 4}
      assert note.duration == 0.5
      assert note.velocity == 90
    end

    test "converts MIDI note 21 to A0 (lowest piano note)" do
      note = Note.midi_to_note(21, 1, 100)
      assert note.note == {:A, 0}
      assert note.duration == 1
      assert note.velocity == 100
    end

    test "converts MIDI note 108 to C8 (high piano note)" do
      note = Note.midi_to_note(108, 1, 100)
      assert note.note == {:C, 8}
      assert note.duration == 1
      assert note.velocity == 100
    end
  end

  describe "Note.note_to_midi/1" do
    test "converts middle C (C4) to MIDI note 60" do
      note = Note.new({:C, 4}, duration: 1, velocity: 100)
      midi = Note.note_to_midi(note)
      assert midi.note_number == 60
      assert midi.duration == 1
      assert midi.velocity == 100
    end

    test "converts C5 to MIDI note 72" do
      note = Note.new({:C, 5}, duration: 2, velocity: 80)
      midi = Note.note_to_midi(note)
      assert midi.note_number == 72
      assert midi.duration == 2
      assert midi.velocity == 80
    end

    test "converts C#4 to MIDI note 61" do
      note = Note.new({:C!, 4}, duration: 0.5, velocity: 90)
      midi = Note.note_to_midi(note)
      assert midi.note_number == 61
      assert midi.duration == 0.5
      assert midi.velocity == 90
    end

    test "converts A0 to MIDI note 21 (lowest piano note)" do
      note = Note.new({:A, 0}, duration: 1, velocity: 100)
      midi = Note.note_to_midi(note)
      assert midi.note_number == 21
      assert midi.duration == 1
      assert midi.velocity == 100
    end

    test "converts C8 to MIDI note 108 (high piano note)" do
      note = Note.new({:C, 8}, duration: 1, velocity: 100)
      midi = Note.note_to_midi(note)
      assert midi.note_number == 108
      assert midi.duration == 1
      assert midi.velocity == 100
    end
  end
  
  describe "Note.enharmonic_equal?/2" do
    test "identifies enharmonic equivalence in raw note tuples" do
      # Test various sharp/flat equivalents
      assert Note.enharmonic_equal?({:C!, 4}, {:Db, 4})
      assert Note.enharmonic_equal?({:D!, 4}, {:Eb, 4})
      assert Note.enharmonic_equal?({:F!, 4}, {:Gb, 4})
      assert Note.enharmonic_equal?({:G!, 4}, {:Ab, 4})
      assert Note.enharmonic_equal?({:A!, 4}, {:Bb, 4})
      
      # Test non-equivalent notes
      refute Note.enharmonic_equal?({:C, 4}, {:D, 4})
      refute Note.enharmonic_equal?({:E, 4}, {:F, 4})
      
      # Test octave differences
      refute Note.enharmonic_equal?({:C, 4}, {:C, 5})
      refute Note.enharmonic_equal?({:C!, 4}, {:Db, 5})
    end
    
    test "identifies enharmonic equivalence in Note structs" do
      c_sharp = Note.new({:C!, 4})
      d_flat = Note.new({:Db, 4})
      assert Note.enharmonic_equal?(c_sharp, d_flat)
      
      f_sharp = Note.new({:F!, 3})
      g_flat = Note.new({:Gb, 3})
      assert Note.enharmonic_equal?(f_sharp, g_flat)
      
      c4 = Note.new({:C, 4})
      c5 = Note.new({:C, 5})
      refute Note.enharmonic_equal?(c4, c5)
    end
  end
end

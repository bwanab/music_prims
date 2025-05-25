defmodule NoteTest do
  use ExUnit.Case
  doctest Note

  describe "Note.new/2" do
    test "creates a note with no duration or velocity" do
      note = Note.new(:C, 4)
      assert note.note == :C
      assert note.octave == 4
      assert note.duration == 1
      assert note.velocity == 100
    end

    test "creates a note with both duration and velocity specified" do
      note = Note.new(:D, 3, 8, 80)
      assert note.note == :D
      assert note.octave == 3
      assert note.duration == 8
      assert note.velocity == 80
    end

    test "creates a note with duration but no velocity, defaults velocity to 100" do
      note = Note.new(:E, 5, 2)
      assert note.note == :E
      assert note.octave == 5
      assert note.duration == 2
      assert note.velocity == 100
    end

  end

  describe "Sonority.show/2" do
    test "formats a natural note correctly without duration" do
      note = Note.new(:C, 4)
      assert Sonority.show(note) == "c'4"
    end

    test "formats a sharp note correctly without duration" do
      note = Note.new(:C!, 4)
      assert Sonority.show(note) == "cis'4"
    end

    test "formats a flat note correctly without duration" do
      note = Note.new(:Bb, 3)
      assert Sonority.show(note) == "bes4"
    end

    test "formats a quarter note (duration 4)" do
      note = Note.new(:C, 4, 4)
      assert Sonority.show(note) == "c'1"
    end

    test "formats a half note (duration 2)" do
      note = Note.new(:D, 3, 2)
      assert Sonority.show(note) == "d2"
    end

    test "formats an eighth note (duration 8)" do
      note = Note.new(:G, 3, 0.5)
      assert Sonority.show(note) == "g8"
    end

    test "formats a sixteenth note (duration 16)" do
      note = Note.new(:A, 5, 0.25)
      assert Sonority.show(note) == "a''16"
    end

    test "formats a whole note (duration 1)" do
      note = Note.new(:E, 2, 4)
      assert Sonority.show(note) == "e,1"
    end

    test "formats a dotted quarter note" do
      note = Note.new(:F, 4, 1.5, 100)
      assert Sonority.show(note) == "f'4."
    end
  end

  describe "MidiNote.midi_to_note/3" do
    test "converts middle C (MIDI 60) to Note struct" do
      note = MidiNote.midi_to_note(60, 1, 100)
      assert note.note == :C
      assert note.octave == 4
      assert note.duration == 1
      assert note.velocity == 100
    end

    test "converts MIDI note 72 to C5" do
      note = MidiNote.midi_to_note(72, 2, 80)
      assert note.note == :C
      assert note.octave == 5
      assert note.duration == 2
      assert note.velocity == 80
    end

    test "converts MIDI note 61 to C#4" do
      note = MidiNote.midi_to_note(61, 0.5, 90)
      assert note.note == :C!
      assert note.octave == 4
      assert note.duration == 0.5
      assert note.velocity == 90
    end

    test "converts MIDI note 21 to A0 (lowest piano note)" do
      note = MidiNote.midi_to_note(21, 1, 100)
      assert note.note == :A
      assert note.octave == 0
      assert note.duration == 1
      assert note.velocity == 100
    end

    test "converts MIDI note 108 to C8 (high piano note)" do
      note = MidiNote.midi_to_note(108, 1, 100)
      assert note.note == :C
      assert note.octave == 8
      assert note.duration == 1
      assert note.velocity == 100
    end
  end

  describe "MidiNote.note_to_midi/1" do
    test "converts middle C (C4) to MIDI note 60" do
      note = Note.new(:C, 4, 4, 100)
      midi = MidiNote.note_to_midi(note)
      assert midi.note_number == 60
      assert midi.duration == 4
      assert midi.velocity == 100
    end

    test "converts C5 to MIDI note 72" do
      note = Note.new(:C, 5, 2, 80)
      midi = MidiNote.note_to_midi(note)
      assert midi.note_number == 72
      assert midi.duration == 2.0
      assert midi.velocity == 80
    end

    test "converts C#4 to MIDI note 61" do
      note = Note.new(:C!, 4, 8, 90)
      midi = MidiNote.note_to_midi(note)
      assert midi.note_number == 61
      assert midi.duration == 8
      assert midi.velocity == 90
    end

    test "converts A0 to MIDI note 21 (lowest piano note)" do
      note = Note.new(:A, 0, 4, 100)
      midi = MidiNote.note_to_midi(note)
      assert midi.note_number == 21
      assert midi.duration == 4
      assert midi.velocity == 100
    end

    test "converts C8 to MIDI note 108 (high piano note)" do
      note = Note.new(:C, 8, 4, 100)
      midi = MidiNote.note_to_midi(note)
      assert midi.note_number == 108
      assert midi.duration == 4
      assert midi.velocity == 100
    end

    test "sanity of midi_note conversion" do
      note = Note.new(:C, 8, 4, 100)
      midi = MidiNote.note_to_midi(note)
      assert MidiNote.midi_to_note(midi) == note
    end
  end

  describe "MidiNote.get_lily_duration/2" do
    test "plain half note" do
      note = Note.new(:C, 3, 2)
      lily = MidiNote.get_lily_duration(Sonority.duration(note), 4)
      assert lily == "2"
    end
    test "plain whole note" do
      note = Note.new(:C, 3, 4)
      lily = MidiNote.get_lily_duration(Sonority.duration(note), 4)
      assert lily == "1"
    end
    test "plain quarter note" do
      note = Note.new(:C, 3, 1)
      lily = MidiNote.get_lily_duration(Sonority.duration(note), 4)
      assert lily == "4"
    end
    test "plain eighth note" do
      note = Note.new(:C, 3, 0.5)
      lily = MidiNote.get_lily_duration(Sonority.duration(note), 4)
      assert lily == "8"
    end
    test "dotted half note" do
      note = Note.new(:C, 3, 3)
      lily = MidiNote.get_lily_duration(Sonority.duration(note), 4)
      assert lily == "2."
    end
    test "dotted quarter note" do
      note = Note.new(:C, 3, 1.5)
      lily = MidiNote.get_lily_duration(Sonority.duration(note), 4)
      assert lily == "4."
    end
    test "dotted eighth note" do
      note = Note.new(:C, 3, 0.75)
      lily = MidiNote.get_lily_duration(Sonority.duration(note), 4)
      assert lily == "8."
    end
    test "dotted 16th note" do
      note = Note.new(:C, 3, 0.375)
      lily = MidiNote.get_lily_duration(Sonority.duration(note), 4)
      assert lily == "16."
    end
    test "long plain note remainder" do
      note = Note.new(:C, 3, 9)
      lily = MidiNote.get_lily_duration(Sonority.duration(note), 4)
      assert lily == "4*9"
    end
    test "long plain note no remainder" do
      note = Note.new(:C, 3, 12)
      lily = MidiNote.get_lily_duration(Sonority.duration(note), 4)
      assert lily == "1*3"
    end
    test "long dotted note" do
      note = Note.new(:C, 3, 9.5)
      lily = MidiNote.get_lily_duration(Sonority.duration(note), 4)
      assert lily == "8*19"
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
      c_sharp = Note.new(:C!, 4)
      d_flat = Note.new(:Db, 4)
      assert Note.enharmonic_equal?(c_sharp, d_flat)

      f_sharp = Note.new(:F!, 3)
      g_flat = Note.new(:Gb, 3)
      assert Note.enharmonic_equal?(f_sharp, g_flat)

      c4 = Note.new(:C, 4)
      c5 = Note.new(:C, 5)
      refute Note.enharmonic_equal?(c4, c5)
    end
  end
end

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
end
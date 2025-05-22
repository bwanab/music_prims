defmodule MidiNote do
  @moduledoc """
  Module for handling MIDI note representations and conversions.
  """

  @type t :: %{note_number: integer, duration: number | nil, velocity: integer}

  # Notes and MIDI mapping - reused from Note module
  @notes [:C, :C!, :D, :D!, :E, :F, :F!, :G, :G!, :A, :A!, :B]
  @sharp_midi_notes Enum.with_index(@notes) |> Enum.map(fn {a, b} -> {a, b+12} end)
  @flat_notes [:C, :Db, :D, :Eb, :E, :F, :Gb, :G, :Ab, :A, :Bb, :B]
  @flat_midi_notes Enum.with_index(@flat_notes) |> Enum.map(fn {a, b} -> {a, b+12} end)
  @midi_notes @sharp_midi_notes ++ @flat_midi_notes
  @midi_notes_map Enum.into(@midi_notes, %{})

  @doc """
  Convert a note to its MIDI note number, duration, and velocity.
  """
  @spec note_to_midi(Note.t) :: t
  def note_to_midi(%Note{note: key, octave: octave, duration: duration, velocity: velocity}) do
    midi_duration = case duration do
      0 -> 0.0
      _ -> 4.0 / duration
    end
    midi_duration = if midi_duration < 0, do: abs(midi_duration) * 1.5, else: midi_duration
    %{
      note_number: @midi_notes_map[key] + (octave * 12),
      duration: midi_duration,
      velocity: velocity || 100
    }
  end

  @doc """
  Convert a MIDI note number to a Note struct.
  """
  @spec midi_to_note(integer, number | nil, integer | nil) :: Note.t
  def midi_to_note(note_number, duration \\ 1, velocity \\ 100) do
    octave = div(note_number - 12, 12)
    key_index = rem(note_number - 12, 12)
    key = Enum.at(@notes, key_index)
    Note.new(key, octave, duration, velocity)
  end

  @doc """
  Convert a note or list of notes to MIDI value(s).
  """
  @spec to_midi(Note.t() | [Note.t()]) :: integer() | [integer()]
  def to_midi(%Note{note: key, octave: octave}) do
    @midi_notes_map[key] + (octave * 12)
  end
  def to_midi(notes) when is_list(notes), do: Enum.map(notes, &to_midi/1)
end
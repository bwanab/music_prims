defmodule Note do
  @type key :: atom()
  @type note :: {key, integer}
  @type note_sequence :: keyword(Note)
  @type scale :: note_sequence
  @type t :: %__MODULE__{
    note: note(),
    duration: float(),
    velocity: integer()
  }

  defstruct [:note, :duration, :velocity]
  
  @doc """
  Compares two notes for enharmonic equality.
  
  This function checks if two notes are the same pitch, even if they are spelled differently.
  For example, {:D!, 4} and {:Eb, 4} are enharmonically equal.
  
  ## Examples
  
      iex> Note.enharmonic_equal?({:C!, 4}, {:Db, 4})
      true
      
      iex> Note.enharmonic_equal?({:F!, 3}, {:Gb, 3})
      true
      
      iex> Note.enharmonic_equal?({:C, 4}, {:D, 4})
      false
  """
  def enharmonic_equal?({key1, octave1}, {key2, octave2}) do
    get_note_number({key1, octave1}) == get_note_number({key2, octave2})
  end
  
  def enharmonic_equal?(%__MODULE__{note: note1}, %__MODULE__{note: note2}) do
    enharmonic_equal?(note1, note2)
  end

  @spec new(note(), keyword()) :: Sonority.t()
  def new(note, opts \\ []) do
    # Extract options with defaults
    velocity = Keyword.get(opts, :velocity, nil)
    duration = Keyword.get(opts, :duration, nil)

    # Apply conditional defaults based on which values are provided
    velocity = if duration != nil && velocity == nil, do: 100, else: velocity
    duration = if velocity != nil && duration == nil, do: 1, else: duration

    # Return the struct with specified values
    %__MODULE__{
      note: note,
      duration: duration,
      velocity: velocity
    }
  end

  # return a rest of a given duration in quarter notes
  def rest(duration) do
    Note.new({:rest, 0}, duration: duration)
  end

  # Format the note following the Guido Music Notation standard
  # https://guidodoc.grame.fr/
  # Examples: C4 (C in octave 4), C#4*1/4 (C# quarter note in octave 4), G3*1/8 (G eighth note in octave 3)
  def to_string(%__MODULE__{note: {key, octave}, duration: duration}) do
    key_str = key |> Atom.to_string() |> String.replace("!", "#")
    base = "#{key_str}#{octave}"

    case duration do
      nil -> base
      1 -> "#{base}*1/4"  # quarter note
      2 -> "#{base}*2/4"  # half note
      0.5 -> "#{base}*1/8"  # eighth note
      0.25 -> "#{base}*1/16"  # sixteenth note
      4 -> "#{base}*4/4"  # whole note
      d when is_number(d) -> "#{base}*#{duration}/4"  # custom duration
      _ -> base
    end
  end

  def midi_to_note(note_number, duration, velocity) do
    # Convert MIDI note number to {key, octave} format
    note_name = get_note_name(note_number)
    %__MODULE__{
      note: note_name,
      duration: duration,
      velocity: velocity
    }
  end

  def note_to_midi(%__MODULE__{note: note, duration: duration, velocity: velocity}) do
    # Convert {key, octave} to MIDI note number
    note_number = get_note_number(note)
    %{note_number: note_number, duration: duration, velocity: velocity}
  end

  # Helper functions for MIDI conversions
  defp get_note_name(note_number) do
    # MIDI note numbers: C0 is 12, C4 (middle C) is 60
    notes = [:C, :C!, :D, :D!, :E, :F, :F!, :G, :G!, :A, :A!, :B]
    octave = div(note_number, 12) - 1
    note_index = rem(note_number, 12)
    key = Enum.at(notes, note_index)
    {key, octave}
  end

  defp get_note_number({key, octave}) do
    # Convert {key, octave} to MIDI note number
    notes = %{C: 0, C!: 1, Db: 1, D: 2, D!: 3, Eb: 3, E: 4, F: 5, F!: 6, Gb: 6, G: 7, G!: 8, Ab: 8, A: 9, A!: 10, Bb: 10, B: 11}
    base = (octave + 1) * 12
    offset = Map.get(notes, key, 0)
    base + offset
  end

  defimpl Sonority do
    def duration(rest) do
      rest.duration
    end

    def type(_) do :note end

  end
end

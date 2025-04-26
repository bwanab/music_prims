defmodule Note do
  @type key :: atom()
  @type note :: {key, integer}
  @type note_sequence :: keyword(Note)
  @type scale :: note_sequence

  defstruct [:note, :duration, :velocity]

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
end

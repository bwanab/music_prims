
defmodule Note do
  @moduledoc """
  Functions for working with musical notes.
  """

  @type t :: %__MODULE__{
    note: atom(),
    octave: integer(),
    duration: number(),
    velocity: integer()
  }

  @type scale :: [t()]

  defstruct [:note, :octave, :duration, :velocity]


  # Circle of fifths and key mapping
  @circle_of_fifths [:C, :G, :D, :A, :E, :B, :F!, :C!, :G!, :D!, :A!, :F]
  @flat_circle_of_fifths [:C, :G, :D, :A, :E, :B, :Gb, :Db, :Ab, :Eb, :Bb, :F]

  @flat_key_map Enum.zip(@circle_of_fifths, @flat_circle_of_fifths) |> Enum.into(%{})
  @normal_flat_key_map @flat_key_map |> Map.merge(%{:F! => :F!, :C! => :C!})
  # @sharp_key_map Enum.zip(@flat_circle_of_fifths, @circle_of_fifths) |> Enum.into(%{})


  def new(key, octave \\ 3, duration \\ 1.0, velocity \\ 100) do
    %__MODULE__{note: key, octave: octave, duration: duration, velocity: velocity}
  end

  @spec copy(Note.t(), keyword()) :: Note.t()
  def copy(%__MODULE__{note: key, octave: octave, duration: duration, velocity: velocity}, opts \\ []) do
    # Handle nil values and defaults
    key = Keyword.get(opts, :key, key)
    octave = Keyword.get(opts, :octave, octave)
    duration = Keyword.get(opts, :duration, duration)
    velocity = Keyword.get(opts, :velocity, velocity)
    Note.new(key, octave, duration, velocity)
  end


  @doc """
  Get the key from a note.
  """
  @spec key_from_note(t()) :: atom()
  def key_from_note(n) when is_atom(n), do: n
  def key_from_note(%__MODULE__{note: key}), do: key




  @doc """
  Move a note or list of notes up or down an octave.
  """
  @spec bump_octave(t() | [t()], :up | :down) :: t() | [t()]
  def bump_octave(%__MODULE__{note: key, octave: octave} = note, :up) do
    %{note | note: key, octave: octave + 1}
  end
  def bump_octave(%__MODULE__{note: key, octave: octave} = note, :down) do
    %{note | note: key, octave: octave - 1}
  end
  def bump_octave(notes, direction) when is_list(notes) do
    Enum.map(notes, &bump_octave(&1, direction))
  end

  @doc """
  Move a note at a specific position up or down an octave.
  """
  @spec bump_octave([t()], integer(), :up | :down) :: [t()]
  def bump_octave(notes, position, direction) do
    List.update_at(notes, position, fn note ->
      bump_octave(note, direction)
    end)
  end

  @doc """
  Move a note or list of notes up an octave.
  """
  @spec octave_up(t() | [t()]) :: t() | [t()]
  def octave_up(%__MODULE__{} = note), do: bump_octave(note, :up)
  def octave_up(notes) when is_list(notes), do: Enum.map(notes, &octave_up/1)

  @doc """
  Map a note to its sharp key.
  """
  @spec map_by_sharp_key(t() | atom(), atom()) :: t() | atom()
  def map_by_sharp_key(note_or_key, context \\ :normal)
  def map_by_sharp_key(%__MODULE__{note: key, octave: octave} = note, context) do
    %{note | note: {map_by_sharp_key(key, context), octave}}
  end
  def map_by_sharp_key(key, context) when is_atom(key) do
    key_map = if context == :normal, do: @normal_flat_key_map, else: @flat_key_map
    Map.get(key_map, key, key)
  end


  @doc """
  Check if two notes are enharmonically equal.
  Handles both Note structs and {key, octave} tuples.
  """
  @spec enharmonic_equal?(t | {atom, integer} | atom, t | {atom, integer} | atom) :: boolean
  def enharmonic_equal?(note1, note2) do
    midi1 = case note1 do
      %Note{} -> MidiNote.to_midi(note1)
      {key, octave} -> MidiNote.to_midi(new(key, octave))
      _ -> MidiNote.to_midi(new(note1, 3))
    end

    midi2 = case note2 do
      %Note{} -> MidiNote.to_midi(note2)
      {key, octave} -> MidiNote.to_midi(new(key, octave))
      _ -> MidiNote.to_midi(new(note2, 3))
    end

    midi1 == midi2
  end

  @spec common_notes(MusicPrims.note_sequence, MusicPrims.note_sequence, boolean) :: integer
  def common_notes(c1, c2, ignore_octave \\ :true)

  def common_notes(c1, c2, ignore_octave) when ignore_octave == :false do
    case List.myers_difference(c1, c2)[:eq] do
      nil -> []
      val -> val

    end
    |> Enum.count
  end

  def common_notes(c1, c2, ignore_octave) when ignore_octave == :true do
    case List.myers_difference(Enum.map(c1, &key_from_note(&1)), Enum.map(c2, &key_from_note(&1)))[:eq] do
      nil -> []
      val -> val
    end
    |> Enum.count
  end


  @spec note_distance(Note.t(), Note.t()) :: integer
  def note_distance(n1, n2) do
    v =
      Stream.iterate(abs(MidiNote.to_midi(n1) - MidiNote.to_midi(n2)), &(&1 - 12))
      |> Stream.drop_while(&(&1 > 12))
      |> Enum.take(1)
      |> List.first
    if v > 6 do 12 - v else v end
  end


  # Implement the Sonority protocol
  defimpl Sonority do
    def duration(note), do: note.duration
    def type(_), do: :note
    @doc """
    Convert a note to a Lilypond string representation.
    """
    # @spec to_string(t()) :: String.t()
    #def to_string(%__MODULE__{note: key, octave: octave, duration: duration}) do
    def show(%Note{note: key, octave: octave, duration: duration}, opts \\ []) do
      no_dur = if Keyword.has_key?(opts, :no_dur), do: Keyword.get(opts, :no_dur), else: false

      b = String.downcase(Atom.to_string(key))
      key_str = case String.length(b) do
        1 -> b
        2 -> case String.at(b, 1) do
          "!" -> "#{String.at(b, 0)}is"
          _ -> "#{String.at(b, 0)}es"
        end
      end

      octave_str = case octave do
        6 -> "'''"
        5 -> "''"
        4 -> "'"
        3 -> ""
        2 -> ","
        1 -> ",,"
        0 -> ",,,"
        _ -> "''"
      end

      if no_dur do
        "#{key_str}#{octave_str}"
      else
        "#{key_str}#{octave_str}#{MidiNote.get_lily_duration(duration)}"
      end
    end

    def to_notes(note) do
      [note]
    end
  end
end
